# Project 1 — Final Scope, Constraints & Acceptance Test Matrix

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines the approved business scope and Definition of Done for Project 1.

It consolidates the requirements established during discovery and becomes the baseline against which architecture, implementation, testing, and final portfolio claims will be evaluated.

Implementation must not expand beyond this scope merely to demonstrate additional tools.

---

# 2. Approved End-to-End Business Flow

The approved business process is:

Product / Signup Event

→ Event Authentication

→ Schema Validation

→ Event Recording

→ Idempotency Check

→ Contact Identity Resolution

→ Company / Workspace Identity Resolution

→ Contact–Company Association

→ Product Signal Aggregation

→ ICP Fit Evaluation

→ Product Intent Evaluation

→ Data Readiness Evaluation

→ Suppression / Blocker Evaluation

→ Qualification Decision

→ Routing Decision

→ HubSpot Update

→ Sales Handoff

→ SLA Tracking

→ Operational Monitoring

This is the end-to-end boundary of Project 1.

---

# 3. Primary Systems

## HubSpot

Primary CRM and GTM lifecycle system of record.

HubSpot owns or exposes:

* Contact identity;
* Company identity;
* Contact–Company relationships;
* qualification visibility;
* routing visibility;
* Sales handoff state;
* lifecycle / Revenue-facing state;
* Sales follow-up information.

---

## PostgreSQL / Supabase

Operational and product-event data layer.

It owns or records:

* raw product events;
* event-processing state;
* event idempotency;
* product-signal aggregation;
* operational audit data;
* selected identity mappings;
* processing diagnostics.

PostgreSQL is not a replacement CRM.

---

## n8n

Primary cross-system orchestration layer.

It coordinates:

* webhook ingestion;
* validation;
* API calls;
* identity resolution;
* processing logic;
* CRM synchronization;
* controlled retries;
* handoff execution.

---

## JavaScript

Used where deterministic transformations or validation logic are clearer and more maintainable in code than through visual nodes alone.

---

# 4. Approved Product Events

Version 1 supports:

* `signup_completed`
* `workspace_created`
* `core_workflow_created`
* `core_workflow_executed`
* `teammate_invited`
* `integration_connected`
* `usage_threshold_reached`
* `upgrade_intent_detected`

Additional events require an explicit requirement change.

---

# 5. Approved Fit States

* `strong_fit`
* `moderate_fit`
* `weak_fit`
* `disqualified`

Fit remains independent from Product Intent.

---

# 6. Approved Intent States

* `low_intent`
* `medium_intent`
* `high_intent`
* `commercial_intent`

The implementation may maintain a transparent numerical aggregation score, but the numerical score is not the final business decision.

---

# 7. Approved Data Readiness States

* `ready`
* `incomplete`
* `ambiguous`
* `blocked`

---

# 8. Approved Qualification States

* `monitoring`
* `pql_candidate`
* `needs_review`
* `sales_ready`
* `handoff_blocked`
* `handed_off`
* `not_qualified`

---

# 9. Approved Handoff States

* `not_started`
* `pending`
* `completed`
* `failed`
* `review_required`

Qualification state and handoff state must remain separate.

---

# 10. Approved SLA States

* `not_started`
* `open`
* `met`
* `breached`
* `not_applicable`

The initial Sales follow-up SLA is one business day after successful handoff.

---

# 11. Approved Routing Targets

* `na_smb`
* `na_mid_market`
* `emea_smb`
* `emea_mid_market`
* `enterprise_review`
* `manual_review`

Routing targets represent business routing intent.

Fake Sales users must not be created to simulate organizational structure.

---

# 12. Resolved Business Decisions

The following previously open decisions are now fixed for Version 1.

## Re-entry after Sales handoff

Automatic re-entry is disabled.

Once an Account reaches:

`handed_off`

new product events may continue to be recorded and aggregated, but they must not automatically create another equivalent handoff.

Re-entry requires a future explicit policy or manual reset outside Version 1.

---

## Active Sales engagement

If the Company already has an active Sales process that satisfies the defined duplicate-engagement condition, a new automatic PQL handoff must not be generated.

The exact HubSpot detection mechanism will be selected during CRM design.

---

## Intent evaluation window

Product Intent uses a rolling 30-day activity window.

Historical events remain in the event ledger for audit purposes but cease contributing to current Intent after the active window unless the event type is explicitly persistent.

---

## Intent downgrade

Before successful Sales handoff, current Intent may decrease when qualifying events leave the 30-day window.

Qualification may therefore move backward where appropriate.

Example:

`sales_ready`

may return to:

`pql_candidate`

if Intent falls before handoff occurs.

Once the Account reaches:

`handed_off`

automatic Intent decay does not undo the completed handoff.

---

## Commercial Intent

`upgrade_intent_detected` is treated as explicit commercial evidence rather than merely additional score.

For Version 1, commercial intent participates in the same 30-day active evaluation window.

---

## Manual review expiry

Version 1 will not automatically expire `needs_review` records.

They remain reviewable until:

* data changes;
* identity is resolved;
* qualification is recalculated;
* an operator takes a defined action.

---

## Manual override

Revenue Operations may control explicit suppression.

Version 1 does not allow an arbitrary manual override that bypasses hard safety rules such as unresolved identity conflicts.

---

## Enterprise Accounts

Accounts with 1,000 or more employees do not automatically enter normal routing.

They use:

`enterprise_review`

This demonstrates controlled exception handling rather than assuming the same motion fits every segment.

---

## Unknown data

Unknown information is represented explicitly.

Missing data must never automatically be interpreted as negative data.

---

# 13. Constraints

The implementation must respect the following constraints.

### CRM Constraint

HubSpot is the only primary CRM in Project 1.

Salesforce is intentionally excluded.

### AI Constraint

No AI or LLM is used to determine qualification.

### Sandbox Constraint

The HubSpot environment may not provide enough real owners for every routing target.

The system must preserve routing intent without fabricating users.

### Security Constraint

No credential, token, password, secret, or private key may be committed to Git.

### Data Constraint

Testing must use synthetic or non-sensitive records.

### Architecture Constraint

PostgreSQL is used for operational/event data, not to duplicate the full HubSpot CRM.

### Reliability Constraint

Project 1 implements meaningful reliability controls but does not attempt to become the deep reconciliation project reserved for Project 2.

### Portfolio Integrity Constraint

No client, production deployment, revenue result, employer, or business result may be invented.

Only implemented and tested capabilities may be claimed.

---

# 14. Non-Goals

Project 1 will not build:

* Salesforce automation;
* Claude or other AI qualification;
* AI lead scoring;
* full outbound sequencing;
* billing infrastructure;
* Customer Success automation;
* enterprise-grade distributed transaction infrastructure;
* a complete data warehouse;
* a standalone BI product;
* large-scale reconciliation infrastructure;
* arbitrary tool integrations added only for portfolio coverage;
* automated multi-cycle Sales re-entry.

---

# 15. Acceptance Test Matrix

The completed system must pass the following defined scenarios.

## AT-01 — Valid New Account Happy Path

Input:

A valid event sequence for a new strong-fit Company with sufficient Product Intent and complete identity data.

Expected:

* events accepted;
* identities resolved;
* Contact and Company available in HubSpot;
* correct association established;
* signals aggregated;
* Fit = strong;
* Intent = high;
* Readiness = ready;
* qualification = sales_ready;
* routing target determined;
* handoff completes;
* qualification becomes handed_off;
* SLA begins.

---

## AT-02 — Signup Only

Input:

Strong-fit Account with only:

`signup_completed`

Expected:

* event recorded;
* Account resolved;
* Intent remains low;
* qualification = monitoring;
* no Sales handoff.

---

## AT-03 — Strong Fit + Medium Intent

Input:

Strong-fit Account with sufficient activity for medium Intent but not high Intent.

Expected:

* qualification = pql_candidate;
* no automatic handoff.

---

## AT-04 — Weak Fit + High Intent

Input:

Weak-fit Account with significant Product Usage.

Expected:

* Product Intent can become high;
* Fit remains weak;
* qualification = not_qualified;
* no Sales handoff.

---

## AT-05 — Moderate Fit + High Intent

Input:

Moderate-fit Account showing high Product Intent.

Expected:

* qualification = needs_review;
* no automatic Sales handoff.

---

## AT-06 — Explicit Commercial Intent

Input:

Strong-fit, ready Account producing:

`upgrade_intent_detected`

Expected:

* commercial intent is recorded separately;
* qualification can become sales_ready;
* successful handoff occurs if no blocker exists.

---

## AT-07 — Missing Critical Data

Input:

Strong-fit/high-intent Account missing a required handoff field.

Expected:

* readiness = incomplete;
* qualification does not automatically hand off;
* Account enters controlled review or candidate state;
* missing requirement is explainable.

---

## AT-08 — Ambiguous Identity

Input:

An event whose product identity conflicts with CRM identity evidence.

Expected:

* no identity guess;
* readiness = ambiguous;
* qualification = needs_review;
* no automatic handoff.

---

## AT-09 — Explicit Suppression

Input:

Strong-fit/high-intent Account marked as suppressed.

Expected:

* suppression overrides qualification;
* qualification = handoff_blocked;
* no Sales handoff.

---

## AT-10 — Internal / Test Account

Input:

High-intent internal or QA Account.

Expected:

* handoff blocked;
* no Sales action generated.

---

## AT-11 — Duplicate Product Event

Input:

Exactly the same `event_id` submitted twice.

Expected:

* first event processed normally;
* second delivery identified as duplicate;
* no duplicate signal contribution;
* no duplicate CRM mutation;
* no duplicate handoff.

---

## AT-12 — Repeated Business Processing After Handoff

Input:

A new valid product event for an Account already in `handed_off`.

Expected:

* event may still be recorded;
* product state may update;
* no duplicate equivalent Sales handoff is generated.

---

## AT-13 — Invalid Event Schema

Input:

Malformed payload or event missing a required identifier.

Expected:

* event rejected or isolated;
* qualification logic does not run;
* failure is observable;
* invalid data does not contaminate CRM state.

---

## AT-14 — Unsupported Event Type

Input:

Validly structured event with an unsupported `event_type`.

Expected:

* controlled rejection;
* reason recorded;
* no CRM business action.

---

## AT-15 — Temporary HubSpot API Failure

Input:

Valid Sales-ready processing while a simulated transient HubSpot operation fails.

Expected:

* technical failure recorded separately from business qualification;
* Account remains commercially qualified;
* controlled retry behavior occurs;
* no uncontrolled duplicate action.

---

## AT-16 — Safe Reprocessing

Input:

An eligible previously failed processing attempt is manually or operationally reprocessed.

Expected:

* processing can resume safely;
* already completed actions are not duplicated;
* final outcome remains traceable.

---

## AT-17 — Existing Sales Engagement

Input:

Account already satisfying the defined active-Sales-engagement condition.

Expected:

* Revenue System does not create redundant Sales work;
* blocking or existing-engagement reason remains visible.

---

## AT-18 — Enterprise Exception

Input:

High-intent Company with 1,000+ employees.

Expected:

* normal automatic routing is avoided;
* routing target = enterprise_review;
* record enters the appropriate review process.

---

## AT-19 — Routing Validation

Input:

Eligible EMEA Mid-Market Account.

Expected:

routing target:

`emea_mid_market`

The routing reason must be explainable from region and segment.

---

## AT-20 — Handoff Failure Does Not Corrupt Qualification

Input:

Account successfully becomes sales_ready but operational handoff fails.

Expected:

Qualification:

`sales_ready`

Handoff:

`failed`

SLA:

`not_started`

The business qualification must not be incorrectly downgraded because of the technical failure.

---

## AT-21 — Successful SLA Start

Input:

Successful completed Sales handoff.

Expected:

* handoff timestamp recorded;
* SLA due timestamp created;
* SLA state = open.

---

## AT-22 — SLA Met

Input:

Defined qualifying Sales activity occurs before the deadline.

Expected:

SLA state:

`met`

---

## AT-23 — SLA Breach

Input:

No qualifying Sales activity occurs before the defined deadline.

Expected:

SLA state:

`breached`

and the condition remains observable.

---

## AT-24 — Intent Aging

Input:

Previously active Account whose qualifying events fall outside the 30-day window before handoff.

Expected:

* Intent recalculates;
* Account can move to a lower qualification state;
* historical events remain available for audit.

---

## AT-25 — Full Traceability

Input:

Any successfully handed-off test Account.

Expected:

An operator can trace:

source event

→ event-processing result

→ identity resolution

→ signal aggregation

→ Fit / Intent / Readiness

→ qualification decision

→ routing

→ HubSpot handoff

→ SLA state.

---

# 16. Definition of Done

Project 1 is complete only when:

1. the approved architecture is implemented;
2. the relevant acceptance tests pass;
3. failures and edge cases have evidence;
4. important processing is traceable;
5. secrets are excluded from source control;
6. implementation documentation is complete;
7. the system can be demonstrated end-to-end;
8. portfolio claims can be mapped to captured evidence;
9. GitHub-ready technical assets exist;
10. a system operator could understand how to run and troubleshoot the implementation.

A visually complete workflow without these conditions does not satisfy the Definition of Done.

---

# 17. Change-Control Rule

After approval of this document, new functionality will only enter Project 1 when:

* an existing requirement cannot be satisfied without it;
* implementation reveals a genuine architecture constraint;
* testing reveals a material reliability gap;
* a required portfolio claim lacks necessary evidence.

Features will not be added solely because a tool supports them.
