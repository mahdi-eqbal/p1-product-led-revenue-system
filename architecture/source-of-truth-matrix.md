# Project 1 — Source-of-Truth & Data Ownership Matrix

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines authoritative ownership for critical data used by the Revenue System.

For each important data element, the architecture specifies:

* source of truth;
* system allowed to write the authoritative value;
* systems allowed to read or persist a copy;
* synchronization direction;
* conflict behavior.

The objective is to prevent unclear ownership and uncontrolled bidirectional synchronization.

---

# 2. Ownership Principles

## Principle 1 — Origin does not always equal presentation layer

Product activity originates in the Product System but selected summaries may be synchronized to HubSpot for Revenue visibility.

---

## Principle 2 — Derived data needs an authoritative calculation layer

Values such as Product Intent are derived from raw events.

Their authoritative calculated state belongs in the operational layer even when a CRM-facing copy exists.

---

## Principle 3 — CRM lifecycle belongs in the CRM

Revenue-facing states such as qualification and handoff must be visible and authoritative in HubSpot.

---

## Principle 4 — Avoid uncontrolled bidirectional writes

A field should normally have one authoritative writer.

Other systems may consume or cache the value but should not independently redefine it.

---

# 3. Core Data Ownership Matrix

| Data Element                 | Source of Truth                       | Authoritative Writer                              | Readers / Copies                             | Sync Direction                     | Conflict Policy                                                                   |
| ---------------------------- | ------------------------------------- | ------------------------------------------------- | -------------------------------------------- | ---------------------------------- | --------------------------------------------------------------------------------- |
| `event_id`                   | Product System / Event Producer       | Product System                                    | PostgreSQL, n8n                              | Product → Revenue System           | Duplicate ID is treated as the same event                                         |
| `event_type`                 | Product System                        | Product System                                    | PostgreSQL, n8n                              | Product → Revenue System           | Invalid/unsupported type is rejected                                              |
| `occurred_at`                | Product System                        | Product System                                    | PostgreSQL, n8n                              | Product → Revenue System           | Original event time is preserved                                                  |
| `product_user_id`            | Product System                        | Product System                                    | PostgreSQL, HubSpot Contact                  | Product → Revenue System → HubSpot | Product identifier wins over email-based guesses                                  |
| `workspace_id`               | Product System                        | Product System                                    | PostgreSQL, HubSpot Company                  | Product → Revenue System → HubSpot | Product identifier wins over domain-based guesses                                 |
| Contact CRM identity         | HubSpot                               | HubSpot                                           | PostgreSQL reference only                    | HubSpot → Operational Layer        | HubSpot record ID is authoritative CRM identity                                   |
| Company CRM identity         | HubSpot                               | HubSpot                                           | PostgreSQL reference only                    | HubSpot → Operational Layer        | HubSpot record ID is authoritative CRM identity                                   |
| Contact email                | HubSpot / approved CRM process        | HubSpot                                           | n8n, PostgreSQL where operationally needed   | HubSpot → Revenue System           | Stable product ID is preferred if email conflicts                                 |
| Company domain               | HubSpot / approved enrichment process | HubSpot                                           | n8n, PostgreSQL where required               | HubSpot → Revenue System           | Domain must not override a trusted `workspace_id` mapping                         |
| Contact–Company association  | HubSpot                               | HubSpot via approved orchestration                | PostgreSQL may retain relationship reference | Revenue System → HubSpot           | Trusted workspace mapping takes precedence over inferred domain association       |
| Employee count               | HubSpot / approved enrichment source  | HubSpot after approved synchronization            | n8n, PostgreSQL calculation context          | Source → HubSpot → Revenue System  | Unknown remains unknown; no silent default                                        |
| Country / commercial region  | HubSpot                               | HubSpot / approved enrichment                     | n8n, PostgreSQL                              | HubSpot → Revenue System           | Explicit CRM value wins over inferred user location                               |
| Industry / business type     | HubSpot / approved enrichment         | HubSpot                                           | n8n                                          | HubSpot → Revenue System           | Missing value remains unknown                                                     |
| Internal-account flag        | HubSpot                               | Revenue Operations                                | n8n                                          | HubSpot → Revenue System           | CRM flag overrides Product Intent                                                 |
| Suppression status           | HubSpot                               | Revenue Operations                                | n8n, PostgreSQL audit if needed              | HubSpot → Revenue System           | Explicit suppression always wins                                                  |
| Suppression reason           | HubSpot                               | Revenue Operations                                | n8n                                          | HubSpot → Revenue System           | Must remain human-readable                                                        |
| Raw product events           | PostgreSQL                            | Revenue ingestion pipeline                        | n8n, reporting                               | Event Producer → PostgreSQL        | Raw event record is not overwritten by CRM state                                  |
| Current Product Intent score | PostgreSQL                            | Revenue calculation logic                         | HubSpot summary                              | PostgreSQL → HubSpot               | PostgreSQL calculation is authoritative                                           |
| Current Product Intent state | PostgreSQL                            | Revenue calculation logic                         | HubSpot                                      | PostgreSQL → HubSpot               | Operational calculation wins if CRM copy differs                                  |
| Commercial-intent status     | PostgreSQL                            | Revenue calculation logic based on product events | HubSpot                                      | PostgreSQL → HubSpot               | Raw event evidence determines state                                               |
| Important signal summary     | PostgreSQL-derived                    | Revenue calculation logic                         | HubSpot                                      | PostgreSQL → HubSpot               | Regenerated from authoritative event data                                         |
| Intent calculation timestamp | PostgreSQL                            | Revenue calculation logic                         | HubSpot                                      | PostgreSQL → HubSpot               | Latest successful calculation wins                                                |
| ICP Fit state                | HubSpot                               | Revenue qualification process                     | n8n, PostgreSQL audit where needed           | Revenue System → HubSpot           | HubSpot stores authoritative Revenue-facing state                                 |
| Data Readiness state         | HubSpot                               | Revenue qualification process                     | PostgreSQL processing/audit                  | Revenue System → HubSpot           | Latest successful evaluation wins                                                 |
| Qualification state          | HubSpot                               | Revenue qualification process                     | PostgreSQL audit                             | Revenue System → HubSpot           | HubSpot is authoritative business state                                           |
| Qualification reason         | HubSpot                               | Revenue qualification process                     | PostgreSQL audit                             | Revenue System → HubSpot           | Must match the latest qualification evaluation                                    |
| Routing target               | HubSpot                               | Revenue routing process                           | PostgreSQL audit                             | Revenue System → HubSpot           | Routing policy result is authoritative                                            |
| Assigned Sales owner         | HubSpot                               | HubSpot / approved routing action                 | n8n                                          | Revenue System → HubSpot           | Actual available HubSpot owner is authoritative                                   |
| Handoff status               | HubSpot                               | Revenue handoff process                           | PostgreSQL audit                             | Revenue System → HubSpot           | Completed status only after successful handoff                                    |
| `sales_ready_at`             | HubSpot                               | Revenue qualification process                     | PostgreSQL audit                             | Revenue System → HubSpot           | First valid transition to Sales Ready is retained per cycle                       |
| `handoff_completed_at`       | HubSpot                               | Revenue handoff process                           | PostgreSQL audit                             | Revenue System → HubSpot           | Written only after successful handoff                                             |
| `sla_due_at`                 | HubSpot                               | Revenue SLA process                               | PostgreSQL/reporting                         | Revenue System → HubSpot           | Derived from completed handoff timestamp                                          |
| `first_sales_action_at`      | HubSpot                               | Sales / CRM activity process                      | n8n/reporting                                | HubSpot → Revenue System           | Actual Sales activity is authoritative                                            |
| `sla_status`                 | HubSpot                               | Revenue SLA evaluation process                    | PostgreSQL/reporting                         | Revenue System → HubSpot           | Recalculated from authoritative timestamps                                        |
| Event processing status      | PostgreSQL                            | Revenue processing pipeline                       | n8n/reporting                                | n8n → PostgreSQL                   | PostgreSQL is durable operational state                                           |
| Processing failure reason    | PostgreSQL                            | Revenue processing pipeline                       | n8n/reporting                                | n8n → PostgreSQL                   | Latest processing attempt may append detail without deleting prior audit evidence |

---

# 4. Identity Conflict Rules

## Product User Conflict

If:

`product_user_id`

points to one HubSpot Contact but the incoming email suggests another Contact:

the system must not silently remap the identity.

Preferred behavior:

→ mark identity as ambiguous;

→ stop automatic Sales handoff;

→ route to review.

Stable product identity is stronger evidence than mutable email, but conflicting mappings still require investigation.

---

## Workspace Conflict

If:

`workspace_id`

is already associated with Company A but the incoming domain suggests Company B:

the system must preserve the trusted workspace mapping and flag the conflict.

Domain must not silently overwrite the authoritative product-to-company mapping.

---

# 5. CRM vs. Operational-State Conflicts

## Product Intent disagreement

Example:

PostgreSQL:

`high_intent`

HubSpot:

`medium_intent`

Resolution:

The current authoritative PostgreSQL calculation wins.

HubSpot should be updated to reflect the operational calculation.

---

## Qualification disagreement

Example:

PostgreSQL audit contains an older qualification:

`pql_candidate`

HubSpot contains:

`sales_ready`

Resolution:

HubSpot remains authoritative for current Revenue-facing qualification state.

The operational layer should treat its record as audit/history rather than overwrite the CRM using stale data.

---

# 6. Manual Revenue Operations Changes

Certain fields are intentionally controlled by Revenue Operations.

Examples:

* suppression status;
* suppression reason;
* approved CRM corrections;
* selected Account ownership decisions.

The automation must not automatically reverse explicit manual governance decisions unless a defined business rule authorizes the change.

---

# 7. Derived vs. Authoritative Data

The architecture distinguishes three categories.

## Source Data

Examples:

* product events;
* Product User ID;
* Workspace ID.

Generated by the source application.

---

## Derived Operational Data

Examples:

* Product Intent score;
* Product Intent state;
* signal summaries.

Calculated from source data.

---

## Revenue Business State

Examples:

* qualification state;
* routing target;
* handoff status;
* SLA status.

These are operational Revenue decisions presented and governed in HubSpot.

---

# 8. Synchronization Direction Summary

### Product System → Revenue System

* product events;
* product identity.

### PostgreSQL → HubSpot

* Product Intent summary;
* relevant product-signal context.

### HubSpot → Revenue System

* CRM identity;
* Fit attributes;
* suppression;
* Sales activity;
* current Revenue state where applicable.

### Revenue System → HubSpot

* evaluated Fit state;
* readiness;
* qualification;
* routing;
* handoff;
* SLA state.

There is no unrestricted HubSpot ↔ PostgreSQL bidirectional synchronization.

Each data path has a defined purpose.

---

# 9. Data Duplication Policy

Copies are allowed only when they support a clear operational requirement.

Examples:

PostgreSQL may store:

* HubSpot Contact ID;
* HubSpot Company ID;

because they are required for integration traceability.

It should not copy every HubSpot Contact or Company property.

HubSpot may store:

* Product Intent state;
* important signal summary;

because Sales and Revenue Operations need the context.

It should not store every raw product event.

---

# 10. Audit Policy

Changes to important derived and business states should remain traceable through one or more of:

* raw product-event history;
* PostgreSQL processing records;
* n8n execution history;
* HubSpot property state;
* qualification reason;
* processing timestamps.

The system does not need full enterprise event sourcing, but critical decisions must be explainable after processing.

---

# 11. Design Principles

## One authoritative owner per important data concept

Avoid competing writers.

## Stable IDs outrank inferred identifiers

Use Product User and Workspace IDs wherever possible.

## Manual governance must be respected

Automation does not casually overwrite explicit Revenue Operations decisions.

## Derived data can be recalculated

Raw evidence should remain preserved.

## CRM copies exist for business usability

Data synchronization into HubSpot must have a Revenue-facing reason.

## Operational copies exist for system execution

PostgreSQL stores CRM references only when required for processing or traceability.

---

# 12. Architecture Review Questions

Before implementation, every important field should be answerable through five questions:

1. Where does this value originate?
2. Which system is authoritative?
3. Who may change it?
4. Which systems need a copy?
5. What happens if values disagree?

If those questions cannot be answered, ownership is not yet sufficiently defined.
