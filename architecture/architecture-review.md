# Project 1 — Architecture Review & Baseline Decisions

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This review validates consistency across the Project 1 requirements, business rules, system architecture, data ownership model, processing sequence, and logical data model before implementation begins.

The decisions in this document resolve ambiguities discovered during architecture review and become part of the approved implementation baseline.

---

# 2. Architecture Review Result

The architecture is approved for implementation subject to the clarifications documented below.

No fundamental redesign is required.

The approved system remains:

Product / Signup Events

→ n8n orchestration

→ PostgreSQL operational/event layer

→ HubSpot CRM and Revenue state

→ deterministic qualification

→ routing

→ Sales handoff

→ SLA and operational monitoring.

---

# 3. Decision — Primary Qualification Entity

Revenue qualification will be performed primarily at the:

**Workspace / HubSpot Company level.**

Product Users and HubSpot Contacts provide:

* identity;
* behavioral evidence;
* Sales communication context.

They do not independently create separate qualification cycles for the same Workspace.

This prevents multiple users from one Account generating duplicate PQL handoffs.

---

# 4. Decision — Location of Revenue Properties

Account-level Revenue properties will primarily live on the HubSpot Company.

Examples include:

* ICP Fit;
* Product Intent;
* Data Readiness;
* qualification state;
* qualification reason;
* routing target;
* suppression;
* handoff status;
* Sales-ready timestamp;
* handoff timestamp;
* SLA state.

Contact properties will be created only where the information is genuinely person-specific.

For example:

* Product User ID;
* user-level identity information;
* selected Contact-level context.

Revenue-state properties will not be duplicated across Contact and Company without a demonstrated business need.

---

# 5. Decision — Disqualified vs. Handoff Blocked

The previous specification allowed some disqualified Accounts to become either:

`not_qualified`

or:

`handoff_blocked`.

The implementation will use the following deterministic rule.

## `not_qualified`

Used when the Account fails the commercial ICP policy.

Examples:

* clearly unsuitable company profile;
* company too small for the defined sales-assisted motion;
* weak business use case.

Meaning:

> This is not currently an Account Sales should pursue through this motion.

---

## `handoff_blocked`

Used when the Account may otherwise be commercially relevant but a governance or operational restriction prevents Sales action.

Examples:

* unsupported commercial region;
* explicit suppression;
* internal/test Account;
* unresolved duplicate;
* existing equivalent Sales engagement.

Meaning:

> Commercial interest may exist, but policy or system conditions prohibit automatic handoff.

This distinction is now fixed.

---

# 6. Decision — Incomplete Data Handling

`data_readiness_state = incomplete`

will not have one universal qualification result.

The following deterministic rule will apply.

## Promising Account

If:

* Fit is strong or moderate;
* Intent is medium, high, or commercial;
* required handoff data is missing;

then:

→ `needs_review`

Reason:

The Account may warrant Sales attention, but automatic handoff is unsafe.

---

## Early / Low-Intent Account

If:

* Intent is low;
* required information is incomplete;

then:

→ `monitoring`

The system does not create unnecessary manual-review work for an Account that is not yet commercially interesting.

---

## PQL Candidate

`pql_candidate` is used for commercially developing Accounts whose data is sufficiently trustworthy but whose Fit/Intent combination does not yet justify Sales handoff.

It is not used as a generic missing-data state.

This resolves the previous ambiguity.

---

# 7. Decision — Missing Identity vs. Ambiguous Identity

These conditions are different.

## Missing Identity

No existing HubSpot Contact or Company is found, but the event contains sufficient trustworthy information to create a new record.

Result:

The system may create the appropriate CRM record according to approved creation rules.

---

## Ambiguous Identity

Multiple plausible records exist or trusted identifiers conflict.

Result:

* no automatic identity guess;
* readiness = `ambiguous`;
* qualification = `needs_review`;
* no Sales handoff.

Therefore:

**Not found ≠ ambiguous.**

---

# 8. Decision — Contact Creation

For a valid product user that cannot be matched to an existing Contact:

a HubSpot Contact may be created when:

* a stable `product_user_id` exists;
* minimum Contact identity requirements are satisfied;
* no conflicting identity evidence exists.

The newly created Contact must persist the stable Product User ID.

---

# 9. Decision — Company Creation

For a valid Workspace that cannot be matched to an existing Company:

a HubSpot Company may be created when:

* stable `workspace_id` exists;
* sufficient business identity exists;
* no conflicting Company evidence exists.

A missing enrichment field such as employee count does not prevent Company creation.

It may affect later Fit or Readiness evaluation.

---

# 10. Decision — Active Sales Engagement

Version 1 will treat an Account as having active Sales engagement when the authoritative HubSpot Company has an associated Deal in an active Sales pipeline stage that has not reached a terminal Won or Lost state.

If such active engagement exists:

a new automated PQL Sales handoff must not be created.

The Account receives:

`handoff_blocked`

with a reason equivalent to:

`Existing active Sales engagement`

This rule prevents Product activity from creating redundant Sales work.

The exact HubSpot Deal-stage query will be finalized during implementation.

---

# 11. Decision — Raw Event and Processing Attempt Separation

A Product Event is unique by:

`event_id`

One raw event is stored once.

A separate Processing Record represents each processing attempt.

Therefore:

Product Event

1 → many

Processing Records.

Example:

`evt_10001`

may have:

Attempt 1 → HubSpot timeout → failed

Attempt 2 → successful → completed

The raw Product Event remains one record.

---

# 12. Decision — Product Intent Authority

PostgreSQL remains authoritative for calculated Product Intent.

This includes:

* score;
* state;
* commercial-intent indicator;
* calculation timestamp;
* important signal summary.

HubSpot receives the Revenue-facing copy.

If the HubSpot copy differs from the latest successfully calculated PostgreSQL state:

the PostgreSQL calculation is used to repair the CRM copy.

This applies only to Product Intent.

It does not mean PostgreSQL is authoritative for HubSpot Revenue business state generally.

---

# 13. Decision — Qualification Authority

Current qualification state remains authoritative in HubSpot.

PostgreSQL may retain:

* evaluation history;
* processing evidence;
* previous decisions.

It must not use stale historical qualification information to overwrite a newer valid HubSpot business state.

---

# 14. Decision — Event Persistence Order

For a valid new event:

1. authenticate request;
2. validate structure;
3. normalize;
4. establish event uniqueness;
5. persist raw event;
6. begin downstream business processing.

No qualification or CRM mutation occurs before durable event persistence succeeds.

---

# 15. Decision — Duplicate Delivery

If the same:

`event_id`

is received again:

the Revenue System performs a safe no-op for the business effects associated with that event.

A duplicate event must not:

* contribute Product Intent twice;
* create a second CRM record;
* create another association;
* create another Sales handoff.

Duplicate detection may still be recorded operationally.

---

# 16. Decision — Intent Aging

Product Intent uses a rolling 30-day activity window.

Raw events remain permanently available according to project retention assumptions.

Derived current Intent may decrease when old qualifying events leave the active window.

Intent aging may affect qualification before handoff.

It cannot undo an already completed Sales handoff.

---

# 17. Decision — Enterprise Accounts

Companies with:

1,000+ employees

will not enter normal automatic SMB/Mid-Market routing.

They use:

`enterprise_review`

and enter:

`needs_review`

unless a later business policy explicitly defines an enterprise automatic route.

---

# 18. Decision — Routing vs. Owner Assignment

Routing logic produces a business routing target independently from the available HubSpot owner.

Example:

`emea_mid_market`

is a business decision.

Actual owner assignment is a CRM execution concern.

If the sandbox lacks the intended Sales organization:

* preserve the correct routing target;
* use only legitimate available owners;
* document the sandbox constraint.

No fake users will be created.

---

# 19. Decision — Sales SLA Trigger

The one-business-day Sales SLA begins only when:

`handoff_status = completed`

It does not begin at:

`sales_ready`.

Therefore a technical handoff failure does not create an artificial Sales SLA breach.

---

# 20. Decision — AI Exclusion

Project 1 remains fully deterministic for qualification.

Claude, AI scoring, and LLM reasoning remain outside the Project 1 architecture.

This is deliberate rather than a missing capability.

Project 3 will demonstrate AI-assisted decision architecture where probabilistic reasoning provides genuine business value.

---

# 21. Approved System Boundaries

## Product System owns

* Product User identity;
* Workspace identity;
* raw Product Event generation.

## PostgreSQL owns

* raw event ledger;
* processing-attempt records;
* Product Intent calculation;
* operational audit state.

## HubSpot owns

* CRM Contact identity;
* CRM Company identity;
* CRM associations;
* Revenue-facing business state;
* suppression;
* routing visibility;
* handoff state;
* SLA-facing state.

## n8n owns no durable business truth

n8n orchestrates interactions between authoritative systems.

---

# 22. Implementation Readiness

The architecture is approved to proceed when:

* system boundaries are defined;
* identity hierarchy is defined;
* data ownership is defined;
* business and technical states are separated;
* qualification rules are deterministic;
* event and handoff idempotency are separated;
* primary data relationships are known;
* required acceptance scenarios are defined.

These conditions are satisfied.

Project 1 may now proceed from architecture into CRM and data-model implementation.

---

# 23. Architecture Baseline Status

**Architecture Gate: APPROVED**

Any later change to a major decision in this baseline must be justified by:

* implementation constraint;
* requirement conflict;
* test failure;
* security issue;
* material design improvement.

Architecture must not be changed merely to add another tool or portfolio feature.
