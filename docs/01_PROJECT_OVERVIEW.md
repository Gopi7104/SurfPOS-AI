# 01 — Project Overview

> **Read this first.** This document explains *what* SurfPOS AI is and *why* it exists. For technical architecture, see [02_ARCHITECTURE.md](02_ARCHITECTURE.md). For the feature-by-feature breakdown, see [05_FEATURES.md](05_FEATURES.md).

---

## 1. What is SurfPOS AI

SurfPOS AI is a **mobile-first, AI-powered, cloud Point-of-Sale (POS) platform** built for small retailers (kirana stores, surf/beach shops, boutique retail, small supermarkets, and similar single-to-multi-store businesses).

It combines four things that are usually sold separately:

1. **A POS system** — barcode billing, cart, receipts, inventory.
2. **A payments platform** — card, UPI, and wallet acceptance via **Surfboard Payments**.
3. **An AI layer** — OCR-based supplier invoice scanning and Gemini-powered business insights.
4. **A cloud backend** — Firebase-based, so merchants never need local servers, local databases, or IT staff.

The entire experience is designed to run from a merchant's own smartphone. No dedicated POS terminal, no separate barcode scanner hardware (the phone camera is the scanner), and no local installation.

## 2. Why We Are Building It

Small retailers are underserved by the current POS market:

- Traditional POS software (desktop-based, Windows-only) requires dedicated hardware, IT setup, and local backups.
- Existing cloud POS products are usually priced for mid-size or enterprise retail, not a single-owner shop.
- Inventory reconciliation after receiving supplier stock is manual, slow, and error-prone — the owner (or an employee) copies numbers from a paper invoice into a spreadsheet or POS by hand.
- Payment acceptance and POS software are frequently bought from different vendors, so reconciliation between "what sold" and "what was paid" is manual.
- Small retailers rarely have access to analytics or business intelligence — that tooling is reserved for larger retail chains with dedicated staff.

SurfPOS AI addresses all four gaps in a single mobile app tied to a single payments relationship (Surfboard Payments).

## 3. Business Problem

| Problem | Impact on merchant |
|---|---|
| No affordable, mobile-only POS | Forced to buy a PC/tablet + POS software + separate barcode scanner |
| Manual invoice entry | Hours per week spent re-typing supplier invoices into inventory |
| Disconnected payments and POS | Manual end-of-day reconciliation, human error, delayed settlement visibility |
| No analytics | Owner cannot see what's selling, what's expiring, or when to reorder |
| Paper receipts only | No digital record for the merchant or the customer |

## 4. Solution

SurfPOS AI is a single Flutter application (phone-first, tablet-friendly) backed by a Node.js/Express API and Firebase, that lets a merchant:

- Register their business and get an active store in minutes (self-serve onboarding).
- Scan a supplier invoice with the phone camera; AI (OCR + Gemini) extracts line items and proposes inventory updates.
- Search or barcode-scan any product during a sale.
- Build a cart and check out, accepting payment through Surfboard Payments (card / UPI / wallet, depending on Surfboard's supported rails).
- Automatically generate and share a digital receipt.
- View sales analytics and AI-generated business insights (e.g. slow-moving stock, reorder suggestions, revenue trends).

Everything is stored in the cloud (Firebase Realtime Database), so the merchant can use any Android/iOS device without local setup or backup responsibility.

## 5. Features (Summary)

Full detail for each of these lives in [05_FEATURES.md](05_FEATURES.md).

1. Merchant Registration & Onboarding
2. Authentication (Firebase Auth — owner + staff roles)
3. Dashboard (daily snapshot: sales, top products, low stock)
4. Inventory Management
5. Barcode Scanner (camera-based, no external hardware)
6. AI Invoice Scanner (OCR + Gemini extraction → inventory update)
7. Billing / Cart / Checkout
8. Payments (Surfboard Payments integration)
9. Digital Receipts (in-app, shareable via link/PDF)
10. Reports
11. Analytics & AI Business Insights
12. Settings (store, tax, receipt template, staff, notifications)

## 6. Future Scope

These are explicitly **out of scope for the initial build** but are architected for (see [02_ARCHITECTURE.md § Future Expansion](02_ARCHITECTURE.md#future-expansion) and [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md)):

- Multi-store / multi-branch management under one merchant account.
- Customer loyalty programs and CRM.
- Supplier-facing portal (suppliers upload invoices directly).
- Offline-first billing with background sync (see offline strategy in architecture doc).
- Marketplace / multi-tenant white-labeling for POS resellers.
- Web-based back-office dashboard (Flutter Web) alongside the mobile app.
- Predictive restocking using historical sales + seasonality (extension of the current AI insights engine).
- Multi-currency / multi-language support for international expansion.
- Hardware integrations (Bluetooth receipt printers, external barcode guns, cash drawers) as optional add-ons.

## 7. Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Frontend | **Flutter** (Dart) | Mobile-first, single codebase for Android & iOS |
| Backend | **Node.js + Express.js** | REST API, business logic, third-party integration |
| Database | **Firebase Realtime Database** | NoSQL JSON-tree, real-time sync |
| Authentication | **Firebase Authentication** | Email/password + phone OTP |
| Storage | **Firebase Storage** | Product images, invoice scans, receipt PDFs |
| AI — OCR | On-device/cloud OCR (e.g. Google ML Kit / Cloud Vision) | Text extraction from invoice photos and barcodes |
| AI — Reasoning | **Gemini API** | Structuring OCR text into line items; generating business insights |
| Payments | **Surfboard Payments** | Card / UPI / wallet acceptance, merchant onboarding, settlement |

Full rationale for each choice is recorded in [08_ARCHITECTURE_DECISIONS.md](08_ARCHITECTURE_DECISIONS.md).

---

**Next:** [02_ARCHITECTURE.md](02_ARCHITECTURE.md) — system architecture, data flow, and folder structure.
