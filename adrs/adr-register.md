# Project 1 — Architecture Decision Register

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

This register records the major architectural decisions made during Project 1.

Each decision is considered accepted unless explicitly superseded by a later ADR.

---

# ADR-001 — HubSpot Will Not Be Used as the Product Event Store

**Status:** Accepted

## Context

FlowPilot generates product events such as signup, workflow execution, teammate invitations, integration connections, and upgrade intent.

Sales and Revenue Operations need selected product context inside HubSpot, but HubSpot is primarily a CRM rather than a raw event-processing system.

Persisting every product event inside HubSpot would:

* unnecessarily expand CRM data volume;
* mix Revenue-facing state with low-level operational data;
* make event replay and aggregation harder;
* tightly couple qualification logic to the CRM;
* make future signal-model changes more difficult.

## Decision

Raw product events will be stored in PostgreSQL.

HubSpot will receive only Revenue-relevant derived information such as:

* current Product Intent;
* important signal summary;
* qualification state;
* qualification reason;
* handoff information.

## Consequences

### Positive

* clean separation between CRM and event data;
* easier event aggregation and recalculation;
* stronger auditability;
* less unnecessary CRM data;
* qualification logic can evolve without rewriting raw history.

### Trade-off

The system now depends on an additional operational data layer and cross-system integration.

---

# ADR-002 — PostgreSQL Will Own Raw Events and Derived Product Intent

**Status:** Accepted

## Context

Product Intent is derived from multiple events across time.

The system needs to support:

* a rolling 30-day activity window;
* repeated-event caps;
* signal aggregation;
* recalculation;
* event traceability.

Calculating this exclusively from CRM properties would make the underlying evidence difficult to inspect and recompute.

## Decision

PostgreSQL will be authoritative for:

* raw product events;
* event-processing state;
* account-level Product Intent calculations;
* current Product Intent state;
* relevant operational signal summaries.

Selected results will be synchronized to HubSpot.

## Consequences

HubSpot remains usable by Sales without becoming the Product Analytics database.

Product Intent can be recalculated from preserved source events when the model changes.

---

# ADR-003 — Stable Product Identifiers Take Priority Over Email and Domain

**Status:** Accepted

## Context

Email addresses and Company domains are useful for CRM matching, but they are not sufficiently stable to serve as the only identity mechanism.

Examples:

* a user's email can change;
* a user may use multiple emails;
* Companies may own several domains;
* domain matching can produce ambiguous Company records.

FlowPilot already conceptually controls stable identities for Product Users and Workspaces.

## Decision

Preferred identifiers will be:

### Contact

`product_user_id`

### Company

`workspace_id`

Email and domain are supporting identity evidence rather than the primary long-term identity key.

HubSpot will store the relevant stable identifiers where appropriate.

## Consequences

Identity resolution becomes more reliable.

However, conflicting evidence between stable IDs and CRM attributes must create a review condition rather than silent remapping.

---

# ADR-004 — Business State, Handoff State, and Processing State Will Remain Separate

**Status:** Accepted

## Context

A technically failed operation does not necessarily change the underlying business decision.

Example:

An Account may correctly qualify as:

`sales_ready`

while the HubSpot handoff API call temporarily fails.

Using one status field for both conditions would incorrectly imply that the Account is no longer commercially qualified.

## Decision

The architecture will maintain separate concepts for:

### Qualification State

Business decision.

Examples:

* `monitoring`
* `sales_ready`
* `handed_off`

### Handoff State

Operational Sales-delivery state.

Examples:

* `pending`
* `completed`
* `failed`

### Processing State

Technical execution state.

Examples:

* `processing`
* `failed`
* `retry_pending`
* `completed`

## Consequences

Failure handling becomes more precise.

Operators can distinguish:

> The Account should go to Sales.

from:

> The system failed to deliver it to Sales.

This separation also enables safe retry behavior.

---

# ADR-005 — Events Must Be Persisted Before Downstream Revenue Mutations

**Status:** Accepted

## Context

If the system changes CRM state before storing the originating event, a failure could leave HubSpot modified without durable evidence explaining why the mutation occurred.

That would damage traceability and make reprocessing unsafe.

## Decision

For valid new events, durable event persistence must occur before downstream qualification or Sales mutations.

Conceptual sequence:

Validate

→ persist event

→ confirm event identity/idempotency

→ perform downstream business processing.

## Consequences

If PostgreSQL is unavailable, Revenue processing stops before CRM mutations occur.

This sacrifices some availability in exchange for stronger traceability and consistency.

For this Revenue workflow, that is the preferred trade-off.

---

# ADR-006 — Event Idempotency and Handoff Idempotency Are Separate Controls

**Status:** Accepted

## Context

Two different duplication problems exist.

### Duplicate Event Delivery

The same:

`event_id`

may arrive multiple times.

### Duplicate Business Action

Different legitimate events may repeatedly cause the same Account to satisfy Sales qualification.

Protecting only the first case does not prevent duplicate Sales handoffs.

## Decision

The architecture will implement two independent protections.

### Event-Level Idempotency

Unique `event_id` prevents the same event from contributing business effects twice.

### Handoff-Level Idempotency

Current Account handoff state prevents repeated equivalent Sales handoffs after a successful handoff.

## Consequences

The system remains safe both when:

* infrastructure redelivers an event;
* legitimate new events continue arriving after Sales handoff.

---

# ADR-007 — n8n Is the Orchestration Layer, Not the Durable Source of Truth

**Status:** Accepted

## Context

n8n provides workflow execution history and excellent cross-system orchestration.

However, workflow execution history alone should not become the permanent business or operational data model.

Depending entirely on workflow history would couple traceability to one automation platform.

## Decision

n8n will orchestrate:

* ingress;
* validation;
* API communication;
* transformation;
* decision execution;
* controlled retry.

Durable operational state will be stored in PostgreSQL.

Revenue-facing state will be stored in HubSpot.

## Consequences

The workflow layer can evolve without losing authoritative state.

Troubleshooting can combine n8n execution details with durable database evidence.

---

# ADR-008 — Qualification Will Remain Deterministic in Project 1

**Status:** Accepted

## Context

The qualification decision uses structured factors:

* ICP Fit;
* Product Intent;
* data readiness;
* suppression;
* existing Sales state.

These inputs can be evaluated through explicit business rules.

Introducing an LLM would add:

* probabilistic output;
* additional failure modes;
* explainability challenges;
* unnecessary cost and complexity.

Project 3 is specifically designed to demonstrate AI-assisted Revenue decision systems where reasoning over unstructured context creates real value.

## Decision

Project 1 will not use AI to determine Sales qualification.

Qualification rules will remain deterministic and inspectable.

## Consequences

The system is easier to test and explain.

AI capability remains intentionally separated into Project 3 rather than being inserted into every project.

---

# ADR-009 — HubSpot Is the Only Primary CRM in Project 1

**Status:** Accepted

## Context

Using both HubSpot and Salesforce without a genuine business requirement would create unnecessary synchronization complexity and weaken the clarity of the case study.

Project 2 already uses Salesforce as its primary CRM.

## Decision

HubSpot is the sole primary CRM for Project 1.

Salesforce will not participate in this architecture.

## Consequences

Project 1 can demonstrate deeper HubSpot-centered Revenue Architecture without artificial CRM-to-CRM synchronization.

Portfolio coverage of Salesforce remains provided by Project 2.

---

# ADR-010 — Routing Intent Is Separate From Physical Owner Assignment

**Status:** Accepted

## Context

A portfolio sandbox may not contain enough real Sales users to represent a realistic multi-region Sales organization.

Creating fake users would misrepresent the implementation.

However, the routing engine still needs to demonstrate realistic business routing.

## Decision

The system will calculate and persist routing targets such as:

* `na_smb`
* `na_mid_market`
* `emea_smb`
* `emea_mid_market`

Actual HubSpot owner assignment will use only legitimate available users.

Sandbox limitations will be explicitly documented.

## Consequences

Routing logic remains realistic and testable without fabricating organizational structure.

---

# ADR-011 — Manual Governance Overrides Automated Positive Signals

**Status:** Accepted

## Context

Revenue Operations may explicitly suppress an Account for legitimate business reasons.

Product activity may later produce high Intent, but automation must not silently reverse explicit governance decisions.

## Decision

Hard governance fields such as explicit suppression take precedence over Product Intent.

Automation may surface the conflict but cannot automatically bypass the suppression.

## Consequences

The system respects human governance while retaining visibility into underlying product activity.

---

# ADR-012 — Raw Evidence and Derived State Will Be Stored Separately

**Status:** Accepted

## Context

Qualification and Intent models can change.

If raw events are overwritten by derived state, the Revenue team cannot later:

* recalculate historical Account state;
* investigate decisions;
* compare revised rules;
* explain why previous outcomes occurred.

## Decision

Raw events remain preserved separately from:

* signal aggregates;
* Intent state;
* qualification state;
* routing results.

Derived values may be recalculated without destroying source evidence.

## Consequences

The architecture gains stronger auditability and future flexibility at the cost of maintaining multiple related data layers.
