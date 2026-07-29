# 16 — AI Module

> Related: [05_FEATURES.md § 6 (AI Invoice Scanner)](05_FEATURES.md#6-ai-invoice-scanner) and [§ 12 (Analytics & AI Business Insights)](05_FEATURES.md#12-analytics--ai-business-insights), [03_DATABASE_DESIGN.md § 4.8](03_DATABASE_DESIGN.md#48-invoicescansmerchantidscanid), [08_ARCHITECTURE_DECISIONS.md ADR-004](08_ARCHITECTURE_DECISIONS.md#adr-004--why-ai-ocr--gemini-for-invoice-scanning-vs-manual-entry-only).

---

## 1. Overview

The AI module has two independent responsibilities, both orchestrated **only from the backend** (never called directly by the Flutter client, so API keys stay server-side and output can be validated before it touches the database — see [02_ARCHITECTURE.md § 5](02_ARCHITECTURE.md#5-ai-layer)):

1. **Invoice Scanning** — OCR + Gemini turn a photographed supplier invoice into structured, catalog-matched line items.
2. **Business Insights** — Gemini turns aggregated sales data into plain-language observations and suggestions.

The exact OCR provider (on-device library vs. cloud API) is an open decision — see [08_ARCHITECTURE_DECISIONS.md § ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made). This document describes the pipeline shape independent of that final choice, noting where the choice matters.

## 2. OCR Flow

```
1. Flutter app captures/selects an invoice photo (feature: AI Invoice Scanner,
   see 05_FEATURES.md § 6).
2. App uploads the image: POST /invoice-scans (multipart) — see
   04_API_DOCUMENTATION.md § 6.
3. Backend stores the raw image in Firebase Storage, creates
   invoiceScans/{merchantId}/{scanId} with status: "processing".
4. Backend runs OCR on the image, producing raw text:
     - Cloud OCR API path: backend sends the image bytes/URL to the OCR
       provider's API and receives text back.
     - On-device OCR path (alternative): OCR would run on the client before
       upload — NOT the chosen approach if invoice text must be validated/
       sanitized server-side before use; document the final choice in
       08_ARCHITECTURE_DECISIONS.md once made.
5. Raw OCR text is stored on invoiceScans/{scanId}.ocrRawText for
   debuggability (see 14_DEVELOPER_GUIDE.md § 9 Debugging).
```

## 3. Gemini Prompting

Once raw OCR text exists, the backend sends it to the Gemini API with a **structuring prompt** whose job is to turn unstructured invoice text into a strict JSON shape the backend can validate and store. Example prompt shape (finalize exact wording during implementation, keep it version-controlled in `backend/src/services/ai/prompts/`):

```
You are extracting line items from a supplier invoice's OCR text for a retail
inventory system. Given the raw text below, return ONLY valid JSON matching
this shape:

{
  "supplierNameGuess": string | null,
  "items": [
    { "rawName": string, "qty": number, "unitPrice": number }
  ]
}

Rules:
- If a quantity or price is not clearly present for a line, omit that line
  rather than guessing.
- Do not invent items not present in the text.
- Numbers must be plain numbers (no currency symbols).

OCR TEXT:
"""
<ocrRawText>
"""
```

- The backend **always validates** Gemini's JSON response against a strict schema (reject/retry on malformed output) before proceeding — never write unvalidated model output to the database (see [07_CODING_RULES.md § 10](07_CODING_RULES.md#10-validation)).
- Prompts are treated as versioned code, not throwaway strings — a prompt change is a change worth a [09_PROMPT_HISTORY.md](09_PROMPT_HISTORY.md) entry if it materially affects extraction behavior.

## 4. Invoice Extraction Pipeline (End-to-End)

```
Image → OCR (raw text) → Gemini (structured {rawName, qty, unitPrice}[])
      → Product Matching (§5) → pending_review scan → merchant confirms
      → Order created + Inventory incremented (see 05_FEATURES.md § 6,
        03_DATABASE_DESIGN.md § 4.7)
```

This mirrors `invoiceScans/{merchantId}/{scanId}` exactly (see [03_DATABASE_DESIGN.md § 4.8](03_DATABASE_DESIGN.md#48-invoicescansmerchantidscanid)) — every stage of the pipeline above writes to a specific field on that one record, so the entire pipeline's state is inspectable from a single node.

## 5. Product Matching

For each Gemini-extracted `rawName`, the backend attempts to match it against the merchant's existing `products/{merchantId}` catalog:

1. **Exact/near-exact match** on name or SKU (fast path).
2. **Fuzzy string match** (e.g. Levenshtein distance or token-based similarity) against product names for the merchant, when no exact match is found.
3. Each candidate match is scored into a **confidence score** (0.0–1.0) stored as `matchConfidence` on the extracted item.
4. If no candidate clears a minimum confidence floor, `matchedProductId` is left `null` and the merchant is prompted to pick or create a product manually during review (see [05_FEATURES.md § 6 UI](05_FEATURES.md#6-ai-invoice-scanner)).

## 6. Confidence Score

- Confidence drives the **review UI**, not automatic action: items are shown grouped/highlighted by confidence tier (e.g. high/medium/low — exact thresholds to be tuned empirically post-launch and recorded here once set).
- **Nothing is written to `inventory` or `orders` based on confidence alone** — every extraction, regardless of confidence, requires an explicit merchant confirm action (`POST /invoice-scans/:scanId/confirm`) per [08_ARCHITECTURE_DECISIONS.md ADR-004](08_ARCHITECTURE_DECISIONS.md#adr-004--why-ai-ocr--gemini-for-invoice-scanning-vs-manual-entry-only). An opt-in auto-confirm-above-threshold mode is explicitly future scope, not Phase 1 behavior.

## 7. Error Handling

| Failure point | Handling |
|---|---|
| Image upload fails / unsupported format | `VALIDATION_ERROR` returned synchronously from `POST /invoice-scans` — never creates a scan record. |
| OCR call fails or times out | `invoiceScans/{scanId}.status = "processing"` never advances; backend retries with backoff up to a limit, then sets status to a failure state and surfaces `AI_PROCESSING_ERROR` to the app (which is listening on the scan node). |
| Gemini returns malformed/non-JSON output | Backend retries the prompt once with a stricter instruction; if it still fails, the scan is marked failed rather than storing garbage data. |
| Gemini returns a plausible but empty item list | Scan still moves to `pending_review` with zero items — the merchant sees "no items detected" and can retake the photo, rather than the request silently erroring. |
| Product matching finds no candidates | Item is included with `matchedProductId: null` — never dropped silently; the merchant must resolve it during review. |

All AI-layer failures are logged with the `scanId` (never with the raw image or full OCR text, to keep logs lean — see [07_CODING_RULES.md § 9](07_CODING_RULES.md#9-logging)) so a failure can be traced back to the specific `invoiceScans` record for debugging.

## 8. Business Insights Generation

- A scheduled job (see [02_ARCHITECTURE.md § 10](02_ARCHITECTURE.md#10-scalability)) feeds recent `analytics/{storeId}/{period}` rollups to Gemini with a prompt asking for a small number (e.g. 1–3) of concrete, plain-language observations and suggested actions (e.g. slow-moving stock, notable sales trends, reorder timing) — see [05_FEATURES.md § 12](05_FEATURES.md#12-analytics--ai-business-insights).
- Insights are advisory only — they never trigger an automatic action (e.g. never auto-create a purchase order); they always surface as a Dashboard/Reports card the merchant can act on manually.
- Output is validated (non-empty, reasonable length) before being stored/displayed — a malformed or empty insights response simply results in no new insight card that cycle, not an error surfaced to the merchant.

## 9. Future AI Features

- Opt-in auto-confirm for invoice scans above a tuned confidence threshold (see §6).
- Multi-page invoice support (currently single-image per scan).
- Predictive restocking using historical sales + seasonality (extends §8).
- Anomaly detection (potential shrinkage/fraud signals) from sales patterns.
- Natural-language "ask your data" interface over analytics, powered by Gemini.
- Supplier name recognition/auto-fill learned over repeated scans from the same supplier.

---

**Next:** [17_FOLDER_STRUCTURE.md](17_FOLDER_STRUCTURE.md) — full directory tree.
