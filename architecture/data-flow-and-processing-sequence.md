# Project 1 — Data Flow & Processing Sequence

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines the runtime processing sequence for product and signup events.

It translates the high-level system architecture into an ordered execution model that can later be implemented in n8n, PostgreSQL, HubSpot, and supporting code.

The sequence explicitly separates:

* ingress;
* validation;
* persistence;
* identity resolution;
* signal calculation;
* business qualification;
* routing;
* Sales handoff;
* operational failure handling.

---

# 2. Primary Happy Path

A valid event follows this sequence:

1. Product System emits event.
2. Event reaches authenticated n8n webhook.
3. Request authentication is validated.
4. Event payload is structurally validated.
5. Payload is normalized.
6. Event is checked for duplicate `event_id`.
7. New event is written to PostgreSQL event ledger.
8. Product user identity is resolved.
9. Workspace / Company identity is resolved.
10. Contact–Company association is verified.
11. Current Account product signals are recalculated.
12. Product Intent is evaluated.
13. HubSpot Fit and governance data is retrieved.
14. Data Readiness is evaluated.
15. Suppression and blocker rules are evaluated.
16. Qualification state is calculated.
17. Qualification result is written to HubSpot.
18. If state is not `sales_ready`, processing completes without Sales handoff.
19. If state is `sales_ready`, routing is calculated.
20. Duplicate-handoff protection is checked.
21. Sales handoff is executed.
22. Handoff success is recorded.
23. Qualification transitions to `handed_off`.
24. SLA timestamps and state are initialized.
25. Processing result is recorded in PostgreSQL.
26. Workflow completes successfully.

---

# 3. Stage A — Event Ingress

## Input

The Product System sends an event to the Revenue System endpoint.

Conceptual payload:

```json
{
  "event_id": "evt_10001",
  "event_type": "integration_connected",
  "occurred_at": "2026-08-23T08:10:00Z",
  "product_user_id": "usr_2041",
  "workspace_id": "ws_873",
  "email": "alex@example.com",
  "properties": {}
}
```

The exact schema will be finalized during the Event Contract stage.

---

## Authentication

The request must contain the approved authentication mechanism.

If authentication fails:

* business processing stops;
* the request is rejected;
* no CRM mutation occurs.

Unauthenticated traffic must never reach qualification logic.

---

# 4. Stage B — Structural Validation

The Revenue System validates required fields.

Initial checks include:

* `event_id` exists;
* `event_type` exists and is supported;
* `occurred_at` is valid;
* `product_user_id` is present where required;
* `workspace_id` is present where required;
* field types are valid.

---

## Invalid Payload Path

If validation fails:

1. Event is not allowed into qualification processing.
2. Rejection reason is captured.
3. Operational status becomes equivalent to `rejected`.
4. No HubSpot business state is changed.
5. Processing terminates.

Example:

Missing:

`event_id`

Result:

`rejected_missing_event_id`

---

# 5. Stage C — Normalization

Valid payloads are normalized before downstream processing.

Possible normalization includes:

* trim whitespace;
* lowercase email;
* lowercase domain;
* normalize country code;
* normalize timestamps;
* normalize empty strings to null;
* standardize event-type representation.

Example:

`Alex@Example.COM`

becomes:

`alex@example.com`

Normalization must not invent missing business data.

---

# 6. Stage D — Idempotency and Event Persistence

The system checks the PostgreSQL event ledger using:

`event_id`

---

## New Event

If no matching event exists:

1. Insert event.
2. Record reception timestamp.
3. Set initial processing status.
4. Continue processing.

---

## Duplicate Event

If `event_id` already exists:

1. Do not insert a second equivalent raw event.
2. Do not reapply Product Intent contribution.
3. Do not repeat CRM mutations.
4. Do not create another Sales handoff.
5. Record or expose duplicate detection where useful.
6. End processing safely.

Duplicate delivery is an expected distributed-systems condition, not necessarily an error.

---

# 7. Stage E — Contact Identity Resolution

The system attempts to resolve the incoming product user to a HubSpot Contact.

Preferred order:

1. Search using `product_user_id`.
2. If no result exists, evaluate normalized email.
3. If exactly one safe Contact is found, use it.
4. If no Contact exists and creation criteria are satisfied, create one.
5. Persist `product_user_id` on the Contact where appropriate.
6. Store the HubSpot Contact ID in operational mapping/reference data.

---

## Contact Conflict

If stable product identity and email evidence point toward conflicting CRM Contacts:

Result:

* identity status = ambiguous;
* automatic processing toward Sales stops;
* qualification may become `needs_review`;
* conflict is recorded.

The workflow must not guess the correct Contact.

---

# 8. Stage F — Company Identity Resolution

If the event belongs to a workspace, the system resolves the workspace to a HubSpot Company.

Preferred order:

1. Search by `workspace_id`.
2. If absent, evaluate normalized business domain where safe.
3. If a single authoritative Company exists, use it.
4. If no Company exists and creation criteria are satisfied, create it.
5. Persist `workspace_id` on the Company.
6. Store the HubSpot Company ID in the operational mapping layer.

---

## Company Conflict

If:

`workspace_id`

maps to one Company but domain evidence indicates another:

the stable workspace mapping is preserved and the conflict is flagged.

Automatic Sales handoff stops until the ambiguity is resolved.

---

# 9. Stage G — Contact–Company Association

Once both CRM identities are resolved:

1. Check whether the Contact is associated with the authoritative Company.
2. If not, create or correct the approved association.
3. Preserve the appropriate primary relationship where required.

The system must not create associations from weak evidence when identity is ambiguous.

---

# 10. Stage H — Product Signal Aggregation

The Revenue System queries the relevant account/workspace product events within the active 30-day Intent window.

It calculates:

* relevant event counts;
* capped repeated-event contributions;
* important signal diversity;
* latest meaningful event;
* commercial-intent presence;
* aggregate Product Intent score;
* Product Intent state.

The resulting account-level signal state is persisted in PostgreSQL.

---

# 11. Stage I — CRM Context Retrieval

The Revenue System retrieves the HubSpot attributes required for business evaluation.

Examples:

* employee count;
* country;
* industry/business type;
* internal-account flag;
* suppression status;
* current qualification state;
* current handoff state;
* active Sales engagement indicator.

Only fields required by the business decision should be retrieved.

---

# 12. Stage J — ICP Fit Evaluation

The system evaluates the current Company against the approved Fit rules.

Output:

* `strong_fit`
* `moderate_fit`
* `weak_fit`
* `disqualified`

The Fit reason should also be generated.

Example:

`Strong fit: supported region, 145 employees, valid B2B business profile`

---

# 13. Stage K — Data Readiness Evaluation

The system checks:

* Contact resolved;
* Company resolved;
* association trusted;
* required Company attributes present;
* qualification inputs present;
* no unresolved identity conflicts.

Output:

* `ready`
* `incomplete`
* `ambiguous`
* `blocked`

---

# 14. Stage L — Blocker Evaluation

The system evaluates hard and review blockers.

Examples:

* internal account;
* explicit suppression;
* unsupported region;
* duplicate CRM identity;
* existing equivalent Sales handoff;
* existing active Sales engagement.

Hard blockers take precedence over positive Intent.

---

# 15. Stage M — Qualification Decision

The deterministic qualification engine receives:

* Fit;
* Intent;
* Readiness;
* blockers;
* current handoff context.

It produces:

* qualification state;
* qualification reason;
* evaluation timestamp.

Example:

Input:

* strong_fit
* high_intent
* ready
* no blocker

Output:

`sales_ready`

---

# 16. Stage N — HubSpot Revenue-State Update

The current qualification result and relevant supporting context are synchronized to HubSpot.

Potential CRM-facing values include:

* Product Intent state;
* important signal summary;
* ICP Fit state;
* Data Readiness state;
* qualification state;
* qualification reason.

If qualification does not require Sales action, processing may finish after this synchronization.

---

# 17. Stage O — Routing

Only `sales_ready` Accounts enter normal routing.

The Revenue System determines:

* region;
* segment;
* routing target.

Example:

Germany
240 employees

→

`emea_mid_market`

If routing cannot be safely determined:

→ `needs_review`

rather than guessed assignment.

---

# 18. Stage P — Duplicate Handoff Protection

Before Sales action is created, the system checks whether the Account already has an equivalent completed handoff.

If:

`handoff_status = completed`

and no approved re-entry condition exists:

* do not create another Sales action;
* retain `handed_off`;
* record a no-op outcome.

This protection is separate from event-level idempotency.

---

# 19. Stage Q — Sales Handoff

If all preconditions are satisfied:

1. set handoff status to pending where required;
2. write routing context;
3. assign an available real owner where appropriate;
4. create or expose the Sales follow-up action;
5. record successful handoff timestamp;
6. set handoff status = completed;
7. transition qualification to `handed_off`.

The exact HubSpot task/action mechanism will be chosen during CRM implementation.

---

# 20. Stage R — SLA Initialization

After successful handoff:

1. set `handoff_completed_at`;
2. calculate `sla_due_at`;
3. set `sla_status = open`.

SLA does not start while handoff is failed or incomplete.

---

# 21. Stage S — Final Processing Record

PostgreSQL records the operational outcome.

The final record should allow an operator to determine:

* source event;
* associated workspace;
* HubSpot Contact ID;
* HubSpot Company ID;
* Product Intent result;
* qualification result;
* handoff outcome;
* technical processing outcome;
* relevant failure or review reason;
* completion timestamp.

---

# 22. Temporary HubSpot API Failure Path

Example:

Qualification has successfully produced:

`sales_ready`

but HubSpot returns a temporary API failure.

Expected behavior:

1. Business qualification remains `sales_ready`.
2. Technical processing records failure.
3. Handoff is not marked completed.
4. SLA does not begin.
5. Controlled retry is scheduled or permitted.
6. Retry must not duplicate already-completed upstream effects.
7. Successful recovery continues from the appropriate safe point.

---

# 23. PostgreSQL Failure Path

If the system cannot safely record a new event in the operational ledger:

business processing must stop before downstream Revenue mutations occur.

Reason:

The architecture requires durable event evidence before applying derived business effects.

This prevents CRM state from changing without corresponding operational traceability.

---

# 24. Unsupported Event Path

If:

`event_type`

is structurally valid but not in the approved event catalog:

1. reject event;
2. record reason where appropriate;
3. do not perform identity resolution;
4. do not change Product Intent;
5. do not mutate Revenue state.

---

# 25. Already-Handed-Off Account Path

A new legitimate product event may arrive for an Account already in:

`handed_off`

Expected behavior:

1. event is accepted and stored;
2. signal state may be recalculated;
3. CRM signal summaries may update where appropriate;
4. automatic equivalent handoff is not repeated;
5. qualification remains governed by the approved no-re-entry policy.

---

# 26. Processing State Model

The technical processing layer should support states conceptually equivalent to:

* `received`
* `validated`
* `processing`
* `completed`
* `rejected`
* `failed`
* `retry_pending`
* `review_required`

These states are distinct from Revenue qualification states.

---

# 27. Processing Sequence Principle

The architecture follows this safety order:

**Authenticate before trust**

**Validate before business logic**

**Persist before downstream mutation**

**Resolve identity before qualification**

**Calculate before handoff**

**Check idempotency before side effects**

**Confirm handoff before SLA**

**Record failures instead of hiding them**

---

# 28. End-to-End Trace Example

Example source event:

`evt_10001`

An operator should eventually be able to trace:

`evt_10001`

→ accepted webhook

→ stored product event

→ product user `usr_2041`

→ workspace `ws_873`

→ HubSpot Contact `...`

→ HubSpot Company `...`

→ Product Intent = high

→ ICP Fit = strong

→ Data Readiness = ready

→ Qualification = sales_ready

→ Routing = emea_mid_market

→ Handoff = completed

→ Qualification = handed_off

→ SLA = open

This traceability is part of the Definition of Done.
