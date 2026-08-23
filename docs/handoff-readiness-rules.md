# Project 1 — Data Readiness, Handoff Blockers & Suppression Rules

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines the conditions that must be satisfied before a qualified Account can be automatically handed to Sales.

Product Intent and ICP Fit determine whether an Account appears commercially interesting.

Data Readiness determines whether the Revenue System has enough reliable information to act safely.

An Account may therefore be:

* high Fit;
* high Intent;
* but still not ready for automatic Sales handoff.

---

# 2. Data Readiness States

The initial system uses four readiness states.

## `ready`

All critical handoff information is available and no blocking condition exists.

The Account may continue to Sales routing.

---

## `incomplete`

One or more required data elements are missing.

The Account must not be automatically handed to Sales until the missing information is resolved.

---

## `ambiguous`

The system cannot confidently determine the correct CRM identity, Company association, or other critical relationship.

The Account requires manual review.

---

## `blocked`

A known business or operational rule prevents automatic handoff.

Examples include suppression, duplicate Account conflict, or existing active Sales engagement.

---

# 3. Minimum Contact Data

For automatic Sales handoff, the relevant Contact should have:

* valid Contact identity;
* stable `product_user_id`;
* valid business email where applicable;
* associated HubSpot Company;
* first name or usable contact identity where available;
* no known suppression condition.

A missing optional profile field must not necessarily block handoff.

The distinction between required and optional data must remain explicit.

---

# 4. Minimum Company Data

For automatic Sales handoff, the Company should have:

* resolved HubSpot Company identity;
* stable `workspace_id`;
* Company name;
* valid Company domain where applicable;
* employee-count information or an approved Fit substitute;
* country or commercial region;
* current ICP Fit state;
* no hard disqualifier.

If a required Fit attribute is unavailable, the Account may move to review rather than being automatically rejected.

---

# 5. Minimum Qualification Data

The following qualification information must be available before automatic handoff:

* `icp_fit_state`;
* `product_intent_state`;
* Product Intent calculation timestamp;
* important signal summary;
* data-readiness state;
* current qualification state;
* routing result or routing target.

The handoff must be explainable from these fields.

---

# 6. Identity Blockers

Automatic handoff is blocked when any of the following exists:

## Contact ambiguity

Examples:

* multiple HubSpot Contacts appear to represent the same product user;
* product identifier maps to conflicting CRM records;
* email points to a different known product identity.

---

## Company ambiguity

Examples:

* one workspace appears mapped to multiple HubSpot Companies;
* domain matching produces multiple plausible Companies;
* stable `workspace_id` conflicts with an existing CRM mapping.

---

## Association ambiguity

The Contact exists and the Company exists, but the system cannot safely determine whether they belong together.

Ambiguous identity must be escalated to manual review rather than guessed.

---

# 7. Duplicate and Existing-Record Blockers

## Duplicate Company

If the Revenue System detects multiple HubSpot Companies that appear to represent the same business, automatic handoff is blocked until the duplicate condition is resolved or an authoritative record is identified.

---

## Duplicate Contact

Duplicate Contact conditions must not cause multiple Sales handoffs.

---

## Existing Sales Handoff

If the Account has already been successfully handed to Sales and no approved re-entry condition exists, the system must not create another equivalent handoff.

---

## Existing Active Sales Engagement

If a relevant active Deal or other defined Sales-owned process already exists, the system should avoid generating redundant Sales activity.

The exact HubSpot condition will be finalized during CRM design.

---

# 8. Suppression Rules

Suppression rules override otherwise valid qualification.

The initial system must support at least the following suppression conditions.

## Internal / Test Account

Internal FlowPilot Accounts, demo Accounts, QA Accounts, and system-generated test records must never enter automatic Sales handoff.

---

## Explicit Suppression

Revenue Operations must be able to explicitly suppress an Account from automated Sales handoff.

Possible reasons include:

* existing strategic handling;
* legal/compliance restriction;
* known poor-fit Account;
* partner or reseller relationship;
* manual Revenue Operations decision.

---

## Unsupported Commercial Region

Accounts outside supported commercial regions must not automatically enter the normal Sales handoff path.

---

## Invalid Business Identity

Disposable, malformed, clearly fake, or non-business identities may block automatic handoff where they prevent reliable Account qualification.

---

# 9. Blocker Severity

The initial blocker model uses three categories.

## Hard Block

Automatic handoff is prohibited.

Examples:

* internal Account;
* explicit suppression;
* unsupported region;
* unresolved duplicate identity;
* existing equivalent handoff.

---

## Review Block

Automatic handoff pauses until a human or controlled process resolves uncertainty.

Examples:

* missing Company size;
* ambiguous Company association;
* enterprise Account requiring special routing;
* partially complete identity.

---

## Warning

The issue is recorded but does not necessarily prevent handoff.

Examples:

* optional field missing;
* non-critical enrichment unavailable;
* secondary signal data stale.

Warnings remain visible for observability.

---

# 10. Readiness Evaluation Logic

A simplified initial decision can be expressed as:

### `ready`

when:

* Contact identity is resolved;
* Company identity is resolved;
* Contact–Company association is trusted;
* required qualification data exists;
* no Hard Block exists;
* no unresolved Review Block exists.

---

### `incomplete`

when:

* one or more required fields are missing;
* identity itself is not ambiguous;
* missing information could potentially be completed automatically or manually.

---

### `ambiguous`

when:

* conflicting identity or association evidence exists.

---

### `blocked`

when:

* an explicit suppression or other Hard Block exists.

---

# 11. Readiness Does Not Equal Qualification

Data Readiness answers:

> Can the system safely hand this Account to Sales?

It does not answer:

> Should Sales pursue this Account?

For example:

### Scenario A

* Strong Fit
* High Intent
* Ready

Possible outcome:

Sales Ready

---

### Scenario B

* Strong Fit
* High Intent
* Ambiguous Company identity

Possible outcome:

Needs Review

---

### Scenario C

* Weak Fit
* High Intent
* Ready

Possible outcome:

Not Qualified or Monitoring

---

### Scenario D

* Strong Fit
* Commercial Intent
* Blocked by explicit suppression

Possible outcome:

Handoff Blocked

---

# 12. Required Handoff Context

When an Account does reach Sales, the system should provide at least:

* Company name;
* primary relevant Contact;
* ICP Fit state;
* Product Intent state;
* important product signals;
* qualification reason;
* routing target;
* handoff timestamp;
* SLA deadline or SLA status;
* any non-blocking warnings.

Sales should not need to inspect raw product events to understand the handoff.

---

# 13. Manual Review Queue

Accounts requiring human attention should be distinguishable from normal monitoring and from permanently blocked Accounts.

The implementation should support a review state for cases such as:

* unresolved identity;
* incomplete but promising Account;
* unusual enterprise Account;
* conflicting CRM data;
* other non-deterministic operational exceptions.

The review mechanism will be finalized during HubSpot and routing design.

---

# 14. Design Principles

## Do not guess identity

Ambiguity must trigger review rather than unsafe automation.

## Missing data is not the same as negative data

An incomplete Account can still be commercially valuable.

## Suppression overrides qualification

Strong Fit and Intent cannot override an explicit business restriction.

## Handoff must be idempotent

A successful handoff must not be recreated because the same event or qualification state is processed again.

## Blockers must be explainable

Revenue Operations must be able to identify why an Account was blocked or routed to review.

---

# 15. Initial Fields Required by the Design

The implementation is expected to require concepts equivalent to:

* `data_readiness_state`
* `handoff_block_reason`
* `suppression_status`
* `suppression_reason`
* `identity_resolution_status`
* `qualification_reason`
* `handoff_status`
* `handoff_timestamp`
* `routing_target`

Exact HubSpot property names and internal names will be finalized during CRM design.

---

# 16. Open Decisions

The following remain intentionally open:

* exact required Contact fields;
* exact required Company fields;
* how active Deals block or modify handoff;
* how manual review is represented in HubSpot;
* whether missing enrichment can auto-retry before review;
* re-entry rules after a prior handoff;
* exact suppression-reason taxonomy;
* how long unresolved review items remain active;
* whether Revenue Operations can manually override specific blockers.
