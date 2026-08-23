# Project 1 — System Architecture Specification

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Architecture Objective

The system converts FlowPilot product activity into reliable, explainable, and traceable Revenue qualification and Sales handoff actions.

The architecture separates three major concerns:

1. **Product and operational state**
2. **CRM and Revenue-facing state**
3. **Cross-system orchestration**

This separation prevents any single platform from being forced to perform responsibilities it is not designed to own.

---

# 2. Primary Architecture

The approved high-level flow is:

Product Event Producer

→ Authenticated n8n Webhook

→ Event Validation and Normalization

→ PostgreSQL Event Ledger

→ Idempotency Decision

→ Identity Resolution

→ HubSpot Contact / Company Resolution

→ Contact–Company Association

→ Product Signal Aggregation

→ ICP Fit Evaluation

→ Product Intent Evaluation

→ Data Readiness / Blocker Evaluation

→ Qualification State Evaluation

→ Routing Decision

→ HubSpot Revenue-State Update

→ Sales Handoff

→ SLA Tracking

→ Operational Monitoring

---

# 3. System Responsibilities

## 3.1 Product Event Producer

Represents the FlowPilot application or product analytics source that produces product-usage events.

Responsibilities:

* generate a globally unique event identifier;
* identify the event type;
* include the event timestamp;
* provide stable product-user identifiers;
* provide workspace identifier when applicable;
* provide event-specific attributes.

The Product Event Producer does not determine Revenue qualification.

---

## 3.2 n8n

n8n is the orchestration layer.

Responsibilities include:

* receiving authenticated events;
* schema validation;
* normalization;
* PostgreSQL operations;
* HubSpot API operations;
* identity-resolution orchestration;
* deterministic decision logic;
* routing execution;
* Sales handoff orchestration;
* controlled retries;
* processing-state updates.

n8n is not the long-term system of record for product events or CRM state.

Workflow execution history supports operational troubleshooting but does not replace PostgreSQL audit state.

---

## 3.3 PostgreSQL / Supabase

PostgreSQL is the operational and product-event data layer.

Responsibilities include:

* storing accepted product events;
* enforcing event uniqueness;
* storing product identity mappings where required;
* maintaining account-level signal state;
* maintaining processing state;
* supporting traceability and operational reporting;
* supporting safe recalculation of Product Intent.

PostgreSQL must not duplicate the entire HubSpot CRM.

Only data required for event processing, signal aggregation, traceability, and system operations should be persisted.

---

## 3.4 HubSpot

HubSpot is the primary CRM and GTM lifecycle system of record.

Responsibilities include:

* Contact records;
* Company records;
* Contact–Company associations;
* CRM-facing ICP Fit visibility;
* Product Intent visibility required by Revenue users;
* Data Readiness visibility;
* qualification state;
* qualification reason;
* routing target;
* Sales handoff state;
* Sales ownership where available;
* Sales follow-up task or equivalent action;
* SLA-facing information.

HubSpot does not store every raw product event.

---

# 4. Architecture Boundary Principle

Each system must own information according to its operational purpose.

### Product event history

Owned by:

PostgreSQL

### CRM identities

Owned by:

HubSpot

### Product identity

Originates in:

FlowPilot Product System

Persisted mapping may exist in:

PostgreSQL and HubSpot unique properties

### Current Revenue qualification

Owned by:

HubSpot

Calculated by:

Revenue System orchestration

### Product-signal aggregation

Owned by:

PostgreSQL operational layer

Relevant summary synchronized to:

HubSpot

### Workflow execution

Owned operationally by:

n8n

Relevant durable processing state stored in:

PostgreSQL

---

# 5. Event Processing Architecture

Every incoming event follows a controlled processing sequence.

## Step 1 — Authentication

The webhook request must pass the defined authentication mechanism.

Unauthenticated requests must not enter business processing.

---

## Step 2 — Structural Validation

The payload must contain required fields and valid value types.

Examples:

* valid `event_id`;
* supported `event_type`;
* valid `occurred_at`;
* required product identity.

Invalid payloads are rejected or recorded as invalid according to the final implementation design.

---

## Step 3 — Normalization

Incoming values are transformed into a consistent internal representation.

Examples:

* email normalization;
* domain normalization;
* country normalization;
* timestamp normalization;
* event-type normalization.

Normalization happens before identity and business-rule evaluation.

---

## Step 4 — Event Persistence

The event is written to PostgreSQL before irreversible downstream Revenue actions occur.

This provides:

* traceability;
* event durability;
* deduplication capability;
* safe operational investigation.

---

## Step 5 — Idempotency Decision

`event_id` is checked against the event ledger.

If the event has already been accepted:

the system must not apply the same business effect again.

Duplicate delivery is treated as a valid operational condition rather than an unexpected system error.

---

# 6. Identity Resolution Architecture

Identity resolution uses stable product identifiers wherever possible.

## Contact Identity

Preferred identifier:

`product_user_id`

Supporting identifiers may include:

* email;
* HubSpot Contact ID.

---

## Company Identity

Preferred identifier:

`workspace_id`

Supporting identifiers may include:

* Company domain;
* HubSpot Company ID.

---

## Resolution Order

The initial preferred logic is:

### Contact

1. Search by `product_user_id`.
2. If no result exists, evaluate email where allowed.
3. Resolve or create the correct Contact.
4. Persist the stable product identifier.

### Company

1. Search by `workspace_id`.
2. If no result exists, evaluate business-domain evidence.
3. Resolve or create the correct Company when safe.
4. Persist the stable workspace identifier.

### Association

Once both entities are resolved:

ensure the Contact is associated with the authoritative Company.

Ambiguity must produce review rather than automatic guessing.

---

# 7. Signal Aggregation Architecture

Raw events remain in PostgreSQL.

Account-level signal state is calculated from relevant events within the approved 30-day window.

The aggregation layer may maintain:

* current Intent score;
* current Intent state;
* commercial-intent status;
* recent important signals;
* last signal timestamp;
* last calculation timestamp.

The raw event ledger remains separate from derived signal state.

This allows signal calculations to change without destroying source evidence.

---

# 8. Qualification Architecture

Qualification receives four major inputs:

## ICP Fit

Example:

`strong_fit`

## Product Intent

Example:

`high_intent`

## Data Readiness

Example:

`ready`

## Blocking Conditions

Example:

`suppression = false`

The deterministic qualification engine produces:

* qualification state;
* qualification reason;
* evaluation timestamp.

Example:

Inputs:

Strong Fit
High Intent
Ready
No Blocker

Output:

`sales_ready`

Reason:

`Strong ICP fit + high product intent + complete handoff data`

---

# 9. Business State and Technical State Separation

The architecture must not use one field to represent both business and technical conditions.

Example:

### Business state

`qualification_state = sales_ready`

### Handoff state

`handoff_status = failed`

### Processing state

`processing_status = retry_pending`

These states describe different realities.

A HubSpot API timeout must not cause the Account to become commercially unqualified.

---

# 10. Routing Architecture

Routing is performed only after the Account reaches:

`sales_ready`

The routing engine uses approved business dimensions such as:

* commercial region;
* account segment.

The result is stored as a business routing target.

Example:

`emea_mid_market`

Routing-target determination remains separate from actual sandbox owner assignment.

---

# 11. Sales Handoff Architecture

A successful handoff involves:

1. qualification confirmation;
2. duplicate-handoff check;
3. routing confirmation;
4. HubSpot Revenue-state update;
5. creation or exposure of the required Sales follow-up action;
6. successful handoff timestamp;
7. SLA initialization.

Only after these operations succeed does:

`handoff_status`

become:

`completed`

and the qualification lifecycle may move to:

`handed_off`.

---

# 12. SLA Architecture

The Sales SLA begins only after a successful handoff.

Required conceptual timestamps include:

* `sales_ready_at`
* `handoff_completed_at`
* `sla_due_at`
* `first_sales_action_at`

SLA evaluation produces:

* `not_started`
* `open`
* `met`
* `breached`
* `not_applicable`

A scheduled evaluation process may later be used to detect SLA breaches.

---

# 13. Reliability Architecture

Project 1 implements the following controls.

## Event Idempotency

Unique `event_id`.

## Handoff Idempotency

Existing successful handoff state checked before creating new Sales action.

## Controlled Retry

Transient infrastructure failures may retry.

## Permanent-Error Separation

Invalid business data must not retry indefinitely.

## Safe Reprocessing

Previously failed processing may resume without duplicating completed effects.

## Failure Visibility

Processing failures must be inspectable.

Deep distributed reconciliation remains outside Project 1 scope.

---

# 14. Security Architecture

## Credentials

Stored only in:

* n8n credential management;
* secure environment configuration;
* server-side Supabase configuration.

Credentials must never appear in:

* Git;
* workflow exports;
* screenshots;
* public documentation.

## Test Data

Use synthetic or non-sensitive records.

## Webhook Authentication

The event ingress endpoint must authenticate event producers.

## Database Access

Supabase access must follow least-privilege principles.

RLS or equivalent protection must be applied where exposed access requires it.

---

# 15. Observability Architecture

The operator should be able to determine:

* which event entered the system;
* whether it was accepted;
* whether it was duplicate;
* which CRM records were resolved;
* what signal state resulted;
* which qualification state resulted;
* whether handoff occurred;
* whether processing failed;
* whether retry or review is required.

Observability sources may include:

* PostgreSQL operational tables;
* n8n execution history;
* HubSpot Revenue-facing properties;
* later reporting queries/views.

---

# 16. Architectural Failure Boundaries

The system has several important boundaries.

## Boundary A

Product Producer → n8n

Possible failures:

* authentication failure;
* malformed payload;
* unsupported event.

## Boundary B

n8n → PostgreSQL

Possible failures:

* unavailable database;
* duplicate event;
* write failure.

## Boundary C

n8n → HubSpot

Possible failures:

* authentication;
* rate limit;
* temporary API error;
* invalid property data;
* unresolved CRM identity.

## Boundary D

Qualification → Handoff

Possible failures:

* routing unresolved;
* duplicate handoff;
* task/action creation failure.

Each boundary must eventually have defined error behavior and test evidence.

---

# 17. Architectural Design Principles

## Persist source evidence before derived decisions

Raw events should survive qualification-model changes.

## Prefer stable identifiers

Product IDs are preferred over mutable attributes such as email.

## Separate raw data from derived state

Events and Intent summaries serve different purposes.

## Separate business state from execution state

Commercial qualification must remain valid even when infrastructure fails.

## Keep cross-system logic outside the CRM where appropriate

HubSpot should not become an event-processing platform.

## Keep CRM-facing context inside the CRM

Sales should not need PostgreSQL access to understand qualification.

## Avoid unnecessary duplication

PostgreSQL should store operationally necessary CRM references, not clone the CRM.

## Design for safe repeated delivery

Receiving an event more than once must be harmless.

---

# 18. Out-of-Scope Architecture

Project 1 does not include:

* Salesforce;
* Claude;
* autonomous AI decisions;
* distributed transaction coordination;
* full billing integration;
* deep CRM-to-billing reconciliation;
* generic enterprise data warehouse;
* automated outbound sequencing.

---

# 19. Architecture Success Criteria

The architecture is acceptable when it can support:

1. authenticated product-event ingestion;
2. durable event history;
3. event idempotency;
4. stable product-to-CRM identity resolution;
5. account-level signal aggregation;
6. independent Fit and Intent evaluation;
7. readiness and blocker evaluation;
8. deterministic qualification;
9. deterministic routing;
10. idempotent Sales handoff;
11. SLA state;
12. controlled failure handling;
13. end-to-end traceability;
14. security boundaries;
15. all approved acceptance-test scenarios.
