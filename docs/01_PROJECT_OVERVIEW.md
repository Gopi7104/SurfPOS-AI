# 01 — Project Overview

> **Rewritten during the Surfboard-alignment documentation pass — supersedes all earlier versions of this file.** **Read this first.** This document explains *what* SurfPOS AI is and *why* it exists. For technical architecture, see [02_ARCHITECTURE.md](02_ARCHITECTURE.md). For entity ownership, see [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md). For the feature-by-feature breakdown, see [05_FEATURES.md](05_FEATURES.md).

---

## 1. What is SurfPOS AI

SurfPOS AI is a **mobile-first, AI-powered, cloud Point-of-Sale (POS) platform** built for small retailers (boutique retail, small supermarkets, surf/beach shops, and similar single-to-multi-store businesses), initially targeting the **Swedish market**.

It combines four things that are usually sold separately:

1. **A POS system** — barcode billing, cart, receipts, inventory.
2. **A payments platform** — card, Swish, and wallet acceptance via **Surfboard Payments**, which is also the system of record for the merchant's business identity, stores, and card-reader devices (see [20_DOMAIN_MODEL.md § 1](20_DOMAIN_MODEL.md#1-the-ownership-principle)).
3. **An AI layer** — OCR-based supplier invoice scanning and Gemini-powered business insights.
4. **A cloud backend** — Firebase-based for application data (inventory, catalog, sales, analytics), so merchants never need local servers, local databases, or IT staff.

The entire experience is designed to run from a merchant's own smartphone. No dedicated POS terminal, no separate barcode scanner hardware (the phone camera is the scanner), and no local installation.

## 2. Why We Are Building It

Small retailers are underserved by the current POS market:

- Traditional POS software (desktop-based) requires dedicated hardware, IT setup, and local backups.
- Existing cloud POS products are usually priced for mid-size or enterprise retail, not a single-owner shop.
- Inventory reconciliation after receiving supplier stock is manual, slow, and error-prone.
- Payment acceptance and POS software are frequently bought from different vendors, so reconciliation between "what sold" and "what was paid" is manual — and the merchant's core business identity (their store, their devices) is fragmented across two unrelated systems.
- Small retailers rarely have access to analytics or business intelligence.

SurfPOS AI addresses all four gaps in a single mobile app built entirely on top of a single payments relationship (Surfboard Payments) for merchant/store/device/payment identity, plus a lightweight application layer (Firebase) for everything Surfboard doesn't and shouldn't own.

## 3. Business Problem

| Problem | Impact on merchant |
|---|---|
| No affordable, mobile-only POS | Forced to buy a PC/tablet + POS software + separate barcode scanner |
| Manual invoice entry | Hours per week spent re-typing supplier invoices into inventory |
| Disconnected payments and POS | Manual end-of-day reconciliation, human error, delayed settlement visibility, and duplicate merchant/store records across two systems that inevitably drift out of sync |
| No analytics | Owner cannot see what's selling, what's expiring, or when to reorder |
| Paper receipts only | No digital record for the merchant or the customer |

## 4. Solution

SurfPOS AI is a single Flutter application (phone-first, tablet-friendly) backed by a Node.js/Express API that lets a merchant:

- Register their business — SurfPOS creates the Merchant and default Store **directly in Surfboard** (see [19_SURFBOARD_WORKFLOWS.md § 1](19_SURFBOARD_WORKFLOWS.md#1-merchant-lifecycle)), not as a separate SurfPOS-owned record that then needs reconciling.
- Scan a supplier invoice with the phone camera; AI (OCR + Gemini) extracts line items and proposes inventory updates.
- Search or barcode-scan any product during a sale.
- Build a cart and check out, accepting payment through whichever rails Surfboard has configured for that Store (card / Swish / wallet).
- Automatically generate and share a digital receipt.
- View sales analytics and AI-generated business insights.

Application data (inventory, catalog, sales history, analytics, AI results) lives in Firebase Realtime Database; merchant/store/device/payment/branding/tips/payment-method data lives in Surfboard and is never duplicated (see [02_ARCHITECTURE.md § 4](02_ARCHITECTURE.md#4-data-ownership-surfboard-vs-firebase)) — so the merchant never has to think about which system owns what, and SurfPOS never has two conflicting copies of the same fact.

## 5. Features (Summary)

Full detail for each of these lives in [05_FEATURES.md](05_FEATURES.md).

1. Merchant Registration & Onboarding (creates the Merchant/Store in Surfboard)
2. Authentication (Firebase Auth — owner + staff roles; identity only, not merchant/store data)
3. Dashboard (daily snapshot: sales, top products, low stock — Firebase-owned analytics)
4. Inventory Management (Firebase-owned)
5. Barcode Scanner (camera-based, no external hardware)
6. AI Invoice Scanner (OCR + Gemini extraction → inventory update)
7. Billing / Cart / Checkout
8. Payments (Surfboard-owned Payment lifecycle, Device linkage, Tips)
9. Digital Receipts (Firebase-owned, distinct from Surfboard's own checkout branding)
10. Reports
11. Analytics & AI Business Insights
12. Settings (SurfPOS's own tax/receipt-template/notification config)
13. Store Capabilities & Payment Methods (Surfboard-owned)
14. Device Management (Surfboard-owned)
15. Branding (Surfboard-owned)

## 6. Future Scope

Explicitly **out of scope for the initial build**, architected for (see [22_DEVELOPMENT_ROADMAP.md](22_DEVELOPMENT_ROADMAP.md), [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)):

- Multi-store / multi-branch management under one merchant account (Surfboard already models many Stores per Merchant — see [20_DOMAIN_MODEL.md § 3](20_DOMAIN_MODEL.md#3-relationship-map) — SurfPOS's multi-store *UI* is the remaining work).
- Customer loyalty programs and CRM.
- Supplier-facing portal.
- Offline-first billing with background sync.
- Marketplace / multi-tenant white-labeling for POS resellers.
- Web-based back-office dashboard (Flutter Web).
- Predictive restocking using historical sales + seasonality.
- Multi-currency / multi-market expansion beyond Sweden.
- Additional hardware integrations beyond Surfboard-linked devices.
- Refunds/partial refunds, split payments, multi-device payment collection (see [15_SURFBOARD_INTEGRATION.md § 12](15_SURFBOARD_INTEGRATION.md#12-future-apis)).

## 7. Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Frontend | **Flutter** (Dart) | Mobile-first, single codebase for Android & iOS, talks only to the SurfPOS backend (see [02_ARCHITECTURE.md § 2](02_ARCHITECTURE.md#2-frontend-flutter)) |
| Backend | **Node.js + Express.js** | REST API, business logic, the sole gatekeeper to both Firebase and Surfboard |
| Application data | **Firebase Realtime Database** | Inventory, catalog, sales, analytics, receipts, AI pipeline data — see [02_ARCHITECTURE.md § 4](02_ARCHITECTURE.md#4-data-ownership-surfboard-vs-firebase) |
| Authentication | **Firebase Authentication** | Identity only — email/password + phone OTP |
| Storage | **Firebase Storage** | Product images, invoice scans, receipt PDFs |
| AI — OCR | On-device/cloud OCR (final choice open — see [08_ARCHITECTURE_DECISIONS.md § ADR-009](08_ARCHITECTURE_DECISIONS.md#adr-009--pending-decisions-to-record-here-once-made)) | Text extraction from invoice photos and barcodes |
| AI — Reasoning | **Gemini API** | Structuring OCR text into line items; generating business insights |
| Merchant / Store / Device / Payments / Branding / Tips / Payment Methods | **Surfboard Payments** | System of record — see [20_DOMAIN_MODEL.md](20_DOMAIN_MODEL.md), [15_SURFBOARD_INTEGRATION.md](15_SURFBOARD_INTEGRATION.md) |

Full rationale for each choice: [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md).

---

**Next:** [02_ARCHITECTURE.md](02_ARCHITECTURE.md) — system architecture, data ownership, and folder structure.
