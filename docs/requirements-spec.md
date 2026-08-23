# Project 1 — Requirements Specification

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Business Objective

FlowPilot requires a reliable Revenue System that converts signup and product-usage activity into structured qualification and Sales handoff decisions.

The system must reduce manual inspection of raw product activity while preserving explainability, data quality, and operational control.

---

## 2. Functional Requirements

### FR-01 — Product Event Ingestion

The system must accept defined product and signup events through an authenticated integration endpoint.

Each event must contain enough information to identify:

* the event;
* the event type;
* when it occurred;
* the product user;
* the workspace/account where applicable;
* event-specific attributes.

---

### FR-02 — Event Validation

Every incoming event must be validated before business processing.

The system must reject or isolate events that:

* do not match the expected schema;
* lack required identifiers;
* contain unsupported event types;
* contain invalid required values.

Invalid events must not silently enter qualification logic.

---

### FR-03 — Event Idempotency

Every product event must have a unique event identifier.

If the same event is received more than once, the system must prevent duplicate business processing.

A repeated event must not create:

* duplicate CRM records;
* duplicate qualification actions;
* duplicate Sales handoffs;
* duplicate Sales tasks.

---

### FR-04 — Operational Event Recording

Accepted events must be recorded in PostgreSQL so their processing history can be inspected independently from HubSpot.

The operational record must allow the system operator to determine whether an event was:

* received;
* validated;
* processed;
* rejected;
* failed;
* safely reprocessed where appropriate.

---

### FR-05 — Contact Identity Resolution

The system must resolve product users to HubSpot Contacts.

Identity resolution should prefer stable product identifiers where available rather than relying exclusively on email addresses.

The design must support a unique product user identifier associated with the HubSpot Contact.

---

### FR-06 — Company / Workspace Identity Resolution

The system must resolve product workspaces/accounts to HubSpot Companies.

The design must support a unique product workspace identifier associated with the HubSpot Company.

Domain matching may be used as supporting evidence but must not be the only identity mechanism where a stable workspace identifier exists.

---

### FR-07 — Contact–Company Association

Once identities are resolved, the system must ensure that the relevant Contact is associated with the correct Company in HubSpot.

Ambiguous identity situations must not trigger automatic Sales handoff.

---

### FR-08 — Product Signal Aggregation

Individual product events must contribute to an accumulated view of Product Intent at the user or account level.

The system must distinguish between isolated low-value activity and combinations of signals that indicate meaningful adoption or purchase intent.

---

### FR-09 — ICP Fit Evaluation

The system must evaluate whether an Account matches defined target-customer criteria.

Fit must be calculated independently from Product Intent.

High Product Intent alone must not automatically make an Account Sales-ready.

---

### FR-10 — Data Readiness Evaluation

Before Sales handoff, the system must determine whether the minimum required CRM and account information is available.

Incomplete critical data must block automatic handoff or route the record to a review state.

---

### FR-11 — Deterministic Qualification

Qualification must be based on explicit, inspectable business rules.

The final qualification decision must consider at least:

* Account Fit;
* Product Intent;
* data readiness;
* suppression/blocking rules;
* existing handoff state.

A single opaque numerical score must not be the sole qualification mechanism.

---

### FR-12 — Qualification State Management

The Revenue System must maintain a defined qualification state for each relevant Account or Contact.

The initial state model will support concepts such as:

* Monitoring;
* PQL Candidate;
* Needs Review;
* Sales Ready;
* Handoff Blocked;
* Handed Off;
* Not Qualified.

Exact state names and transitions will be finalized during qualification design.

---

### FR-13 — Sales Routing

Sales-ready records must receive a deterministic routing target based on defined business rules.

Routing may consider factors such as:

* geography;
* account segment;
* company size;
* qualification tier.

Where the sandbox cannot represent multiple real Sales owners, routing intent must still be captured without fabricating users.

---

### FR-14 — Sales Handoff

A successful Sales handoff must provide sufficient context for Sales to understand why the Account was qualified.

The handoff must make relevant information available in HubSpot, including:

* qualification status;
* qualification reason;
* important product signals;
* Fit status;
* Product Intent status;
* routing target;
* handoff timestamp;
* SLA information where applicable.

---

### FR-15 — Duplicate Handoff Prevention

An Account that has already been handed off must not automatically generate another equivalent handoff unless a defined re-entry condition exists.

---

### FR-16 — SLA Tracking

The system must record enough information to determine when a Sales handoff occurred and whether the defined follow-up SLA has been satisfied or breached.

---

### FR-17 — Failure Visibility

Integration failures must be visible to the system operator.

Failures must not disappear silently.

At minimum, the implementation must distinguish between:

* invalid business data;
* transient integration/API failures;
* unresolved identity;
* processing failures.

---

### FR-18 — Controlled Retry

Transient integration failures should be retried using a controlled policy where retry is safe.

Permanent business-data errors must not be retried indefinitely.

---

### FR-19 — Safe Reprocessing

The system must support controlled reprocessing of eligible failed events without duplicating previously completed business actions.

---

### FR-20 — Operational Reporting

The system must expose enough information to understand:

* event processing volume;
* accepted and rejected events;
* duplicate events;
* qualification outcomes;
* Sales handoffs;
* blocked handoffs;
* processing failures;
* relevant SLA status.

---

## 3. Non-Functional Requirements

### NFR-01 — Explainability

A Revenue Operations user must be able to understand why a record reached a particular qualification state.

### NFR-02 — Traceability

Important processing actions must be traceable from source event through CRM outcome.

### NFR-03 — Reliability

Duplicate delivery or temporary API failure must not create uncontrolled duplicate business actions.

### NFR-04 — Maintainability

Business rules should be separated from credentials and unnecessary implementation-specific assumptions.

### NFR-05 — Security

Secrets, API tokens, passwords, and private credentials must not be stored in source-controlled project files.

### NFR-06 — Data Minimization

Only data required for the Revenue process should be persisted in the operational layer.

### NFR-07 — Observability

Operators must be able to distinguish successful, rejected, failed, and review-required processing states.

### NFR-08 — Testability

Qualification, validation, idempotency, routing, and failure-handling behavior must be testable with reproducible input scenarios.

---

## 4. Constraints

* HubSpot is the primary CRM.
* PostgreSQL/Supabase is the operational and product-event data layer.
* n8n is the primary cross-system orchestration layer.
* Project 1 will use deterministic qualification rather than AI-based qualification.
* Real clients, production deployments, and business results must not be fabricated.
* The HubSpot sandbox may contain fewer Sales users than a production organization.
* Test data must not require sensitive real-person information.
* Tool selection must follow business requirements rather than portfolio-logo coverage.

---

## 5. Non-Goals

Project 1 will not attempt to build:

* an AI qualification or recommendation engine;
* a full outbound sequencing platform;
* a complete customer-success system;
* a billing system;
* a Salesforce integration;
* enterprise-grade distributed reconciliation;
* a large standalone BI platform;
* a generic data warehouse;
* functionality whose only purpose is demonstrating a tool.

Deep reconciliation and failure-recovery engineering belong primarily to Project 2.

AI reasoning and evaluation belong primarily to Project 3.

---

## 6. Initial Acceptance Criteria

The implementation will not be considered complete unless the following can be demonstrated:

### AC-01

A valid product event can enter the system and be successfully recorded and processed.

### AC-02

An invalid event is rejected without contaminating qualification state.

### AC-03

Submitting the same event twice does not duplicate downstream business actions.

### AC-04

An existing product user can be resolved to the correct HubSpot Contact.

### AC-05

A workspace can be resolved to the correct HubSpot Company.

### AC-06

Contact and Company associations are correctly maintained.

### AC-07

Product activity updates the correct account-level signal state.

### AC-08

High Fit plus sufficient Intent plus sufficient data can produce a Sales-ready outcome.

### AC-09

High Intent with insufficient Fit does not automatically create a Sales handoff.

### AC-10

Missing critical data produces a controlled review or blocked state rather than an unsafe handoff.

### AC-11

A Sales-ready Account receives the appropriate routing result.

### AC-12

A successful handoff writes sufficient qualification context into HubSpot.

### AC-13

Repeated qualification processing does not create duplicate handoff actions.

### AC-14

A temporary integration failure follows the defined retry behavior.

### AC-15

A failed or unresolved event remains observable to the system operator.

### AC-16

A previously failed eligible event can be safely reprocessed.

### AC-17

Operational reporting can show processing and qualification outcomes.

### AC-18

The full happy path can be demonstrated from raw product event through final HubSpot Sales handoff.

---

## 7. Requirements Still Requiring Design Decisions

The following items are intentionally not finalized yet:

* exact product event catalog;
* event JSON contract;
* ICP Fit criteria;
* Product Intent model;
* signal weighting;
* required handoff fields;
* qualification state transitions;
* suppression rules;
* routing matrix;
* SLA duration and rules;
* enrichment requirements;
* retry policy;
* PostgreSQL schema;
* HubSpot properties;
* precise monitoring implementation.

These will be resolved through the subsequent design gates rather than guessed during implementation.
