# Project 1 — Product Intent Model

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines how FlowPilot converts product activity into an account-level Product Intent classification.

Product Intent measures how strongly product behavior indicates meaningful adoption or possible commercial interest.

Product Intent is evaluated independently from ICP Fit.

A high-intent Account is not automatically Sales Ready.

---

# 2. Intent States

The initial Product Intent model uses four states:

## `low_intent`

The Account has entered the product but has not yet demonstrated meaningful adoption.

Typical signals:

* signup only;
* workspace creation without deeper usage;
* isolated low-value activity.

---

## `medium_intent`

The Account has started using important product capabilities but has not yet demonstrated strong adoption or commercial intent.

Typical signals:

* core workflow created;
* occasional workflow execution;
* early team collaboration.

---

## `high_intent`

The Account demonstrates meaningful product adoption, technical commitment, repeated usage, or multiple reinforcing signals.

Typical signals:

* repeated workflow execution;
* integration connected;
* teammate expansion;
* meaningful usage threshold reached;
* strong combination of adoption signals.

---

## `commercial_intent`

The Account has generated an explicit signal associated with possible purchase or expansion.

Example:

* `upgrade_intent_detected`

Commercial Intent is stronger than general product adoption but still does not override Fit, data readiness, suppression rules, or existing handoff state.

---

# 3. Initial Event Contribution Model

The system may use internal points to aggregate repeated or combined signals.

These points are used for transparent system logic and reporting, not as the final qualification decision.

| Event                     |                  Initial Intent Contribution |
| ------------------------- | -------------------------------------------: |
| `signup_completed`        |                                            5 |
| `workspace_created`       |                                           10 |
| `core_workflow_created`   |                                           15 |
| `core_workflow_executed`  | 10 per qualifying execution, subject to caps |
| `teammate_invited`        |                                           15 |
| `integration_connected`   |                                           30 |
| `usage_threshold_reached` |                                           35 |
| `upgrade_intent_detected` |                                           50 |

These values are implementation assumptions for the case study and may be adjusted through testing.

---

# 4. Initial Intent Thresholds

The first implementation will use the following aggregate ranges:

| Aggregate Intent Score | Intent State    |
| ---------------------- | --------------- |
| 0–14                   | `low_intent`    |
| 15–39                  | `medium_intent` |
| 40–69                  | `high_intent`   |
| 70+                    | `high_intent`   |

`commercial_intent` is not derived only from the score.

It is set when an explicit commercial-intent event exists, such as `upgrade_intent_detected`.

This prevents an account from being classified as commercially interested merely because it generated many low-value events.

---

# 5. Important Intent Rules

## Rule 1 — Repeated low-value events must not inflate Intent indefinitely

Repeated activity can be meaningful, but some events require caps.

For example:

100 workflow executions should not necessarily produce 1000 intent points.

The implementation must prevent repeated high-frequency events from dominating the model.

---

## Rule 2 — Signal diversity matters

A combination of different strong signals is generally more meaningful than repetition of one weak signal.

For example:

* workspace created;
* teammate invited;
* integration connected;
* repeated workflow execution;

provides stronger evidence than repeated signup-like activity.

---

## Rule 3 — Account-level aggregation is primary

Product Intent should ultimately represent the workspace or Account rather than only an individual Contact.

Multiple users may contribute signals to the same workspace.

---

## Rule 4 — Explicit commercial intent is distinct

An explicit upgrade-related signal has different business meaning from ordinary product activity.

It should be stored and reported separately from the aggregate Product Intent score.

---

## Rule 5 — Intent does not override Fit

The following situation remains possible:

`weak_fit + commercial_intent`

This does not automatically create a Sales handoff.

---

# 6. Initial Aggregation Window

The initial model will evaluate meaningful activity over a rolling 30-day period.

This helps distinguish:

* recent active usage;
* historical activity that is no longer relevant.

Events may remain permanently stored in the event ledger for audit purposes while only recent qualifying events contribute to current Product Intent.

---

# 7. Signal Caps

To prevent noisy events from dominating the model, the initial implementation will apply caps.

Example assumptions:

## `core_workflow_executed`

Maximum Intent contribution within the active window:

30 points

This means repeated workflow execution demonstrates adoption but cannot independently produce unlimited Intent.

## `teammate_invited`

Multiple teammate invitations may strengthen intent, but their total contribution should also be capped.

Exact implementation values will be finalized during signal-processing design.

---

# 8. Example Intent Calculations

## Example A — Early user

Events:

* signup completed = 5
* workspace created = 10

Total:

15

Intent:

`medium_intent`

Interpretation:

The Account has activated but has not yet demonstrated strong adoption.

---

## Example B — Active evaluator

Events:

* signup completed = 5
* workspace created = 10
* core workflow created = 15
* core workflow executed = 10
* teammate invited = 15

Total:

55

Intent:

`high_intent`

Interpretation:

The Account demonstrates meaningful usage and team adoption.

---

## Example C — Technical commitment

Events:

* signup completed = 5
* workspace created = 10
* integration connected = 30

Total:

45

Intent:

`high_intent`

Interpretation:

The integration connection provides strong evidence of product commitment.

---

## Example D — Explicit buying signal

Events:

* signup completed = 5
* workspace created = 10
* upgrade intent detected = 50

Aggregate score:

65

Intent:

`commercial_intent`

Interpretation:

The Account has generated explicit buying interest.

Final Sales readiness still requires Fit and data readiness checks.

---

# 9. Intent Output

The Revenue System should produce at least the following account-level values:

* `product_intent_score`
* `product_intent_state`
* `commercial_intent_detected`
* `intent_last_calculated_at`
* `important_signal_summary`

These values may exist in PostgreSQL and selected results may be synchronized to HubSpot for Revenue visibility.

Exact system ownership will be finalized in the Source-of-Truth Matrix.

---

# 10. Explainability Requirement

Every Intent classification must be explainable.

A system operator should be able to answer:

> Why is this Account classified as high intent?

A valid explanation might be:

> Integration connected, two teammates added, and repeated core workflow execution occurred within the last 30 days.

The system must not return only:

> Intent Score = 62

without supporting signal context.

---

# 11. Open Decisions

The following are intentionally deferred:

* exact caps for repeated events;
* signal decay behavior;
* treatment of events older than 30 days;
* whether explicit commercial intent expires;
* exact multi-user aggregation logic;
* whether specific industries require different intent thresholds;
* whether later versions should support adaptive weighting.

The first implementation will remain deterministic and transparent.
