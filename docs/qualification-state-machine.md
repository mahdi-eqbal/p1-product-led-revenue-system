# Project 1 — Qualification State Machine

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines the deterministic qualification states and transition rules used by FlowPilot's Revenue System.

The state machine combines:

* ICP Fit;
* Product Intent;
* Data Readiness;
* suppression and blocker conditions;
* current Sales handoff state.

The objective is to make qualification predictable, explainable, and testable.

---

# 2. Qualification States

The initial system uses seven primary states.

## `monitoring`

The Account is known to the Revenue System but has not yet demonstrated sufficient conditions for Sales action.

Typical situations:

* strong Fit but low Intent;
* moderate Fit and low Intent;
* early product adoption;
* insufficient signals for escalation.

---

## `pql_candidate`

The Account shows meaningful Product Intent and may be approaching Sales readiness.

Typical situations:

* strong Fit + medium Intent;
* moderate Fit + high Intent;
* strong adoption but insufficient evidence for automatic handoff.

This state represents commercial potential without yet committing Sales resources.

---

## `needs_review`

The Account appears potentially valuable, but deterministic automation cannot safely make the final decision.

Typical causes:

* identity ambiguity;
* incomplete important Fit information;
* enterprise Account requiring special handling;
* conflicting CRM data;
* unusual routing situation.

---

## `sales_ready`

The Account satisfies all automatic qualification conditions and is ready for routing and Sales handoff.

Typical requirements:

* acceptable ICP Fit;
* sufficient Product Intent;
* data readiness = ready;
* no active blocker;
* no duplicate handoff condition.

---

## `handoff_blocked`

The Account would otherwise be commercially relevant but a business or operational rule prevents automatic handoff.

Examples:

* explicit suppression;
* unsupported region;
* unresolved duplicate;
* existing equivalent Sales engagement;
* internal/test Account.

---

## `handed_off`

A valid Sales handoff has already been completed.

This state prevents repeated processing from generating duplicate equivalent Sales actions.

---

## `not_qualified`

The Account currently does not meet the commercial qualification policy.

Typical situations:

* weak Fit with insufficient strategic reason for review;
* disqualified Account;
* clearly unsuitable business profile.

`not_qualified` does not necessarily mean that event ingestion stops.

Future activity may still be stored and evaluated according to approved re-entry rules.

---

# 3. Core Decision Order

Qualification must follow a defined evaluation order.

The initial order is:

1. Check hard blockers and suppression.
2. Evaluate identity and data readiness.
3. Evaluate ICP Fit.
4. Evaluate Product Intent.
5. Check existing Sales handoff / active engagement.
6. Determine qualification state.
7. Produce qualification reason.

The order matters.

For example, the system should not calculate a Sales-ready outcome and only afterward discover that the Account is explicitly suppressed.

---

# 4. Initial Decision Logic

## Rule A — Hard Block

If a Hard Block exists:

→ `handoff_blocked`

Examples:

* internal/test Account;
* explicit suppression;
* unsupported region;
* unresolved duplicate;
* prohibited existing Sales condition.

---

## Rule B — Ambiguous Identity

If:

* Contact identity is ambiguous;
* Company identity is ambiguous;
* Contact–Company association cannot be trusted;

then:

→ `needs_review`

The system must not guess.

---

## Rule C — Critical Data Incomplete

If:

* the Account appears commercially promising;
* but required data is missing;

then:

→ `needs_review`

or remain:

→ `pql_candidate`

depending on the missing information and Intent level.

Exact transition logic will be finalized during implementation.

---

## Rule D — Strong Fit + Low Intent

If:

* Fit = `strong_fit`;
* Intent = `low_intent`;
* Readiness is not blocked;

then:

→ `monitoring`

---

## Rule E — Strong Fit + Medium Intent

If:

* Fit = `strong_fit`;
* Intent = `medium_intent`;

then:

→ `pql_candidate`

unless a blocker or review condition exists.

---

## Rule F — Strong Fit + High Intent

If:

* Fit = `strong_fit`;
* Intent = `high_intent`;
* Readiness = `ready`;
* no blocker exists;

then:

→ `sales_ready`

---

## Rule G — Strong Fit + Commercial Intent

If:

* Fit = `strong_fit`;
* Intent = `commercial_intent`;
* Readiness = `ready`;
* no blocker exists;

then:

→ `sales_ready`

---

## Rule H — Moderate Fit + High Intent

If:

* Fit = `moderate_fit`;
* Intent = `high_intent`;

then:

→ `needs_review`

The system should not automatically reject a highly engaged Account because one Fit dimension is uncertain.

---

## Rule I — Moderate Fit + Commercial Intent

If:

* Fit = `moderate_fit`;
* Intent = `commercial_intent`;

then:

→ `needs_review`

A human or Revenue Operations review is appropriate before automatic Sales handoff.

---

## Rule J — Weak Fit + High or Commercial Intent

If:

* Fit = `weak_fit`;
* Intent = `high_intent` or `commercial_intent`;

then:

→ `not_qualified`

unless a specific business exception routes the Account to review.

The default system must not allow high usage to override clearly poor ICP Fit.

---

## Rule K — Disqualified

If:

* Fit = `disqualified`;

then:

→ `handoff_blocked`

or:

→ `not_qualified`

depending on the reason.

Examples:

* unsupported commercial region → `handoff_blocked`
* clearly invalid target customer → `not_qualified`

The reason must remain visible.

---

# 5. Sales Handoff Transition

A record may transition:

`sales_ready`

→ `handed_off`

only after the handoff operation succeeds.

The system must not mark the Account as `handed_off` merely because qualification succeeded.

This distinction is important.

Qualification and operational execution are separate events.

---

# 6. Handoff Failure

If an Account is:

`sales_ready`

but the handoff operation fails because of a transient integration problem:

the business qualification remains valid.

The system should preserve:

`sales_ready`

while recording a separate processing or handoff failure state.

The Account must not be demoted to `monitoring` because an API call failed.

This separates:

**business state**

from:

**technical processing state**

---

# 7. Duplicate Handoff Protection

If:

* qualification is recalculated;
* Account state = `handed_off`;
* no approved re-entry rule exists;

then:

the system must not create a new equivalent Sales handoff.

The Account remains:

`handed_off`

---

# 8. Initial State Transition Examples

## Scenario A — New strong-fit signup

Fit:

`strong_fit`

Intent:

`low_intent`

Readiness:

`ready`

Result:

`monitoring`

---

## Scenario B — Strong-fit account begins adoption

Previous state:

`monitoring`

New Intent:

`medium_intent`

Result:

`pql_candidate`

---

## Scenario C — Strong-fit account reaches high intent

Previous state:

`pql_candidate`

Fit:

`strong_fit`

Intent:

`high_intent`

Readiness:

`ready`

Result:

`sales_ready`

---

## Scenario D — Qualification succeeds and handoff succeeds

Previous state:

`sales_ready`

Sales handoff:

successful

Result:

`handed_off`

---

## Scenario E — High intent but ambiguous Company

Fit:

`strong_fit`

Intent:

`high_intent`

Readiness:

`ambiguous`

Result:

`needs_review`

---

## Scenario F — High intent but explicit suppression

Fit:

`strong_fit`

Intent:

`commercial_intent`

Suppression:

true

Result:

`handoff_blocked`

---

## Scenario G — Weak-fit high-usage Account

Fit:

`weak_fit`

Intent:

`high_intent`

Readiness:

`ready`

Result:

`not_qualified`

---

# 9. Business State vs. Processing State

Qualification state must not be used to represent technical execution problems.

For example:

Business state:

`sales_ready`

Technical processing state:

`hubspot_update_failed`

These are different concerns.

The architecture will therefore maintain separate concepts for:

* qualification state;
* event-processing state;
* Sales handoff state.

This avoids mixing business meaning with infrastructure errors.

---

# 10. Qualification Reason

Every qualification evaluation must generate an explainable reason.

Examples:

`Strong ICP fit + high product intent + complete handoff data`

`Moderate ICP fit + commercial intent requires manual review`

`Sales handoff blocked: explicit account suppression`

`Monitoring: strong fit but insufficient product intent`

`Not qualified: weak ICP fit despite high product usage`

The final implementation should persist or expose this explanation for Revenue Operations and Sales.

---

# 11. State Transition Principles

## Deterministic

The same valid inputs should produce the same qualification result.

## Explainable

Every state must have a human-readable reason.

## Idempotent

Reprocessing the same underlying state must not create repeated business actions.

## Reversible where appropriate

Changes in Fit, Intent, readiness, or suppression may change qualification state when business policy allows.

## Separate from technical failure

API errors must not silently alter business qualification.

---

# 12. Initial Transition Matrix

| Fit                  | Intent     | Readiness  | Blocker    | Result                                                  |
| -------------------- | ---------- | ---------- | ---------- | ------------------------------------------------------- |
| Strong               | Low        | Ready      | No         | `monitoring`                                            |
| Strong               | Medium     | Ready      | No         | `pql_candidate`                                         |
| Strong               | High       | Ready      | No         | `sales_ready`                                           |
| Strong               | Commercial | Ready      | No         | `sales_ready`                                           |
| Moderate             | Low        | Ready      | No         | `monitoring`                                            |
| Moderate             | Medium     | Ready      | No         | `pql_candidate`                                         |
| Moderate             | High       | Ready      | No         | `needs_review`                                          |
| Moderate             | Commercial | Ready      | No         | `needs_review`                                          |
| Weak                 | Any        | Ready      | No         | `not_qualified`                                         |
| Any                  | Any        | Ambiguous  | No         | `needs_review`                                          |
| Any                  | Any        | Incomplete | No         | `needs_review` or `pql_candidate` depending on severity |
| Any                  | Any        | Any        | Hard Block | `handoff_blocked`                                       |
| Disqualified         | Any        | Any        | Any        | `handoff_blocked` or `not_qualified`                    |
| Qualified previously | Any        | Ready      | No         | `handed_off` unless re-entry applies                    |

---

# 13. Open Decisions

The following remain intentionally open:

* exact re-entry policy after `handed_off`;
* whether `pql_candidate` requires a minimum Fit level;
* how long an Account can remain in `needs_review`;
* whether stale Intent causes downgrade;
* whether Intent decay can move `sales_ready` back to `monitoring`;
* exact treatment of active Deals;
* manual override rules;
* whether `not_qualified` can automatically re-enter qualification later.

These will be resolved before implementation of the qualification engine.
