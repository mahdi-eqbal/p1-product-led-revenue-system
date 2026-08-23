# Project 1 — Routing, Sales Handoff & SLA Policy

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines how Sales-ready Accounts are routed, what information must be included in a Sales handoff, how duplicate handoffs are prevented, and how Sales follow-up SLA is measured.

Qualification answers:

> Should Sales act?

Routing and handoff answer:

> Where should the Account go, what should Sales know, and how do we ensure the action happens exactly once?

---

# 2. Routing Principles

Routing must be:

* deterministic;
* explainable;
* based on business attributes;
* independent from individual workflow implementation;
* safe when a specific Sales owner is unavailable.

The initial routing model uses:

1. commercial region;
2. company segment;
3. exception conditions.

---

# 3. Account Segments

The initial implementation uses the following operational segments.

| Employee Count | Segment             |
| -------------- | ------------------- |
| 20–199         | `smb`               |
| 200–999        | `mid_market`        |
| 1,000+         | `enterprise_review` |
| Unknown        | `segment_review`    |

Accounts below the preferred ICP range normally do not reach automatic Sales routing.

---

# 4. Commercial Regions

The initial supported routing regions are:

## `north_america`

* United States
* Canada

## `emea`

* United Kingdom
* European Economic Area

## `region_review`

Other potentially supportable regions requiring review.

Unsupported commercial regions are blocked before normal routing.

---

# 5. Routing Targets

The initial routing targets are:

* `na_smb`
* `na_mid_market`
* `emea_smb`
* `emea_mid_market`
* `enterprise_review`
* `manual_review`

These represent **routing intent**, not fabricated Sales users.

---

# 6. Routing Matrix

| Region               | Segment    | Routing Target      |
| -------------------- | ---------- | ------------------- |
| North America        | SMB        | `na_smb`            |
| North America        | Mid-Market | `na_mid_market`     |
| EMEA                 | SMB        | `emea_smb`          |
| EMEA                 | Mid-Market | `emea_mid_market`   |
| Any supported region | Enterprise | `enterprise_review` |
| Unknown / unresolved | Any        | `manual_review`     |

---

# 7. Sandbox Owner Constraint

The implementation may not contain enough real HubSpot Sales users to represent every routing target.

The system must not create fake Sales users only for portfolio demonstration.

Therefore:

* `routing_target` records the intended business routing result;
* an available real fallback owner may be assigned where required for functional testing;
* the difference between routing intent and sandbox owner assignment must remain documented.

This allows the business logic to remain realistic without fabricating organizational structure.

---

# 8. Routing Preconditions

Routing occurs only when:

* qualification state = `sales_ready`;
* data readiness = `ready`;
* no Hard Block exists;
* identity resolution is complete;
* the Account has not already received an equivalent handoff;
* a valid routing target can be determined.

If routing cannot be safely determined:

→ `needs_review`

rather than guessing.

---

# 9. Sales Handoff Context

Sales must receive enough context to understand why the Account requires attention.

The handoff should expose at least:

## Account Context

* Company name;
* Company domain;
* account segment;
* commercial region;
* relevant Contact.

## Qualification Context

* ICP Fit state;
* Product Intent state;
* qualification state;
* qualification reason;
* data-readiness state.

## Product Context

* important product-signal summary;
* recent meaningful product activity;
* commercial-intent indicator where applicable.

## Routing Context

* routing target;
* handoff status;
* handoff timestamp.

## SLA Context

* SLA due timestamp;
* current SLA status.

Sales should not need to inspect raw event records or PostgreSQL tables to understand why the handoff occurred.

---

# 10. Handoff Actions

A successful automatic handoff should perform a controlled set of CRM actions.

The initial design expects actions equivalent to:

1. update relevant HubSpot qualification properties;
2. persist routing target;
3. record handoff timestamp;
4. assign an appropriate available owner where implementation permits;
5. create or expose a Sales follow-up action;
6. record successful handoff status.

Exact HubSpot-native actions will be finalized during CRM implementation.

---

# 11. Separation of Qualification and Handoff

Qualification and handoff must remain separate states.

Example:

Account becomes:

`sales_ready`

This means:

> The business rules approve Sales action.

Only after the operational handoff succeeds does the Account become:

`handed_off`

This distinction prevents an API or CRM failure from falsely appearing as a successful Sales handoff.

---

# 12. Handoff Status

The initial handoff lifecycle uses concepts equivalent to:

* `not_started`
* `pending`
* `completed`
* `failed`
* `review_required`

Qualification state and handoff status are stored separately.

Example:

Qualification:

`sales_ready`

Handoff:

`failed`

The Account remains commercially qualified even though the operational action needs recovery.

---

# 13. Duplicate Handoff Prevention

A successful handoff must not be recreated simply because:

* another product event arrives;
* qualification is recalculated;
* the workflow is retried;
* the same event is replayed.

Before creating a handoff action, the system must check the current handoff state.

If an equivalent handoff already exists:

→ no duplicate Sales action is created.

The processing result should record that no new handoff was required.

---

# 14. Re-Entry Policy

The first version does not automatically create repeated Sales handoffs after an Account reaches `handed_off`.

Future re-entry may be allowed only through a defined business event such as:

* previous Sales engagement formally closed;
* a new qualification cycle begins;
* a significant new commercial-intent event occurs after an approved cooldown;
* Revenue Operations explicitly resets the handoff state.

Automatic re-entry is outside the initial implementation unless later requirements justify it.

---

# 15. Sales SLA

The initial Sales follow-up SLA is:

**1 business day after successful Sales handoff.**

The SLA clock starts when the handoff has actually completed.

It does not start merely because an Account becomes `sales_ready`.

This avoids penalizing Sales for an integration failure that prevented the handoff from reaching them.

---

# 16. SLA Timestamps

The design should support concepts equivalent to:

* `sales_ready_at`
* `handoff_completed_at`
* `sla_due_at`
* `first_sales_action_at`
* `sla_status`

---

# 17. SLA States

The initial SLA states are:

## `not_started`

No completed Sales handoff exists.

## `open`

Handoff completed and the SLA deadline has not yet passed.

## `met`

A qualifying Sales action occurred before the deadline.

## `breached`

The deadline passed without the required Sales action.

## `not_applicable`

The Account does not currently require Sales follow-up.

---

# 18. What Counts as Sales Action

For the portfolio implementation, the final measurable Sales action will be selected based on what the HubSpot environment can reliably represent.

Possible examples include:

* completing the generated Sales task;
* updating a defined follow-up property;
* recording a qualifying Sales activity.

The selected mechanism must be deterministic and testable.

---

# 19. SLA Example

Account:

Strong Fit

High Intent

Ready

Routing:

`emea_mid_market`

Qualification becomes:

`sales_ready`

at:

Monday 10:00

Handoff successfully completes:

Monday 10:03

The SLA begins at:

Monday 10:03

and is due according to the one-business-day policy.

If the handoff had failed at Monday 10:03, the Sales SLA would not begin until the operational handoff eventually succeeded.

---

# 20. Handoff Failure

If qualification succeeds but handoff fails:

Qualification:

`sales_ready`

Handoff:

`failed`

SLA:

`not_started`

The failure must remain observable and eligible for controlled recovery.

A technical error must not silently change the Account back to `monitoring`.

---

# 21. Manual Review Routing

Accounts requiring review should not be mixed with normal Sales-ready routing.

Examples include:

* moderate Fit + high Intent;
* enterprise Account;
* unresolved routing information;
* ambiguous identity;
* missing important Company data.

These Accounts use:

`manual_review`

or another explicitly defined review queue.

---

# 22. Routing Explainability

The system must be able to explain routing decisions.

Example:

> Routed to EMEA Mid-Market because Company country = Germany and employee count = 240.

The system should not expose only:

> Routing Target = EMEA-2

without business context.

---

# 23. Initial Required CRM Concepts

The later HubSpot data model is expected to require properties equivalent to:

* `routing_target`
* `qualification_state`
* `qualification_reason`
* `handoff_status`
* `sales_ready_at`
* `handoff_completed_at`
* `sla_due_at`
* `sla_status`
* `first_sales_action_at`

Exact property labels and internal names will be finalized during HubSpot design.

---

# 24. Design Principles

## Route by policy, not workflow layout

Routing rules represent business policy and should not depend on where a branch happens to appear inside n8n.

## Qualification precedes routing

An Account must not be routed merely because its geographic or segment information exists.

## Handoff success must be observable

The system must distinguish attempted handoff from completed handoff.

## SLA begins after successful delivery

Sales responsibility begins only after the handoff has actually reached the Sales process.

## Do not fabricate organization structure

Sandbox limitations must be documented instead of hidden through fake Sales users.

---

# 25. Open Decisions

The following will be finalized during implementation:

* exact HubSpot Sales task mechanism;
* actual available fallback owner;
* exact representation of the manual-review queue;
* exact business-calendar handling for the one-business-day SLA;
* whether Sales activity is measured through Task completion or another HubSpot signal;
* whether routing rules later include additional criteria;
* approved future re-entry conditions.
