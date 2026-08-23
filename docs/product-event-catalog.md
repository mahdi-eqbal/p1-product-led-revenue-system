# Project 1 — Product Event Catalog

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines the product and signup events used by the Revenue System and explains the business meaning of each event.

The event catalog separates raw product activity from Revenue interpretation.

An individual event does not automatically create a Sales handoff. Events contribute evidence toward Product Intent, while final qualification also depends on Account Fit, data readiness, suppression rules, and current handoff state.

---

## 2. Core Event Catalog

| Event                     | Primary Entity | Signal Category      | Revenue Meaning                                                                                      | Initial Intent Strength |
| ------------------------- | -------------- | -------------------- | ---------------------------------------------------------------------------------------------------- | ----------------------- |
| `signup_completed`        | User           | Acquisition          | A new user has successfully created an account                                                       | Low                     |
| `workspace_created`       | Workspace      | Activation           | The user has moved beyond registration and created a working environment                             | Medium                  |
| `core_workflow_created`   | Workspace      | Product Adoption     | The account has configured a core product capability                                                 | Medium                  |
| `core_workflow_executed`  | Workspace      | Product Adoption     | The account has successfully used the core product rather than only configuring it                   | Medium–High             |
| `teammate_invited`        | Workspace      | Collaboration        | Product usage is expanding beyond a single individual                                                | Medium–High             |
| `integration_connected`   | Workspace      | Technical Commitment | The account has invested effort in connecting FlowPilot to another system                            | High                    |
| `usage_threshold_reached` | Workspace      | Adoption Depth       | Product usage has crossed a defined level associated with meaningful adoption                        | High                    |
| `upgrade_intent_detected` | Workspace      | Commercial Intent    | The account has performed an explicit action indicating possible interest in a paid or expanded plan | Very High               |

---

# 3. Event Definitions

## `signup_completed`

### Meaning

The user has completed registration and now exists as a product user.

### Revenue interpretation

This is an acquisition signal, not strong buying intent.

A signup alone must never automatically trigger Sales handoff.

### Expected identifiers

* `event_id`
* `event_type`
* `occurred_at`
* `product_user_id`
* `email`

A workspace identifier may not yet exist.

---

## `workspace_created`

### Meaning

The user has created a FlowPilot workspace.

### Revenue interpretation

This represents a stronger activation signal than registration because the user has begun configuring the product.

It still does not independently justify Sales outreach.

### Expected identifiers

* `event_id`
* `event_type`
* `occurred_at`
* `product_user_id`
* `workspace_id`

---

## `core_workflow_created`

### Meaning

The workspace has configured one of FlowPilot's core workflow capabilities.

### Revenue interpretation

The Account is beginning to use the product for a real business process.

This is stronger evidence of adoption than workspace creation.

---

## `core_workflow_executed`

### Meaning

A configured workflow has successfully executed.

### Revenue interpretation

This demonstrates realized product usage rather than setup activity alone.

Repeated successful executions may indicate increasing Product Intent.

---

## `teammate_invited`

### Meaning

A user has invited another person into the workspace.

### Revenue interpretation

Collaboration is expanding beyond a single-user evaluation.

This may indicate organizational adoption and is therefore stronger than individual usage alone.

The number of teammates and rate of team expansion may later contribute to signal aggregation.

---

## `integration_connected`

### Meaning

The workspace has connected FlowPilot to an external business system.

### Revenue interpretation

Connecting an integration normally requires more effort and implies greater product commitment than passive exploration.

This is considered a strong Product Intent signal.

An integration connection still does not override poor ICP Fit or missing critical CRM data.

---

## `usage_threshold_reached`

### Meaning

The workspace has exceeded a defined usage threshold during a specified time window.

Examples may later include:

* workflow execution count;
* active-user count;
* number of configured workflows;
* activity frequency.

### Revenue interpretation

This event represents sustained adoption rather than a single isolated interaction.

The exact threshold will be defined during Product Intent design.

---

## `upgrade_intent_detected`

### Meaning

A product user has performed an action that explicitly suggests interest in an expanded or paid plan.

Possible triggers may include:

* selecting an upgrade action;
* requesting access to a paid capability;
* starting an upgrade flow;
* submitting a plan-interest action.

### Revenue interpretation

This is the strongest initial commercial-intent event in the catalog.

However:

High commercial intent does not automatically create a Sales handoff.

The system must still evaluate:

* Account Fit;
* identity resolution;
* data readiness;
* suppression rules;
* existing handoff state.

---

# 4. Signal Categories

The event catalog uses four broad types of Revenue evidence.

## Acquisition

Indicates that a user has entered the product.

Example:

`signup_completed`

---

## Activation

Indicates that the user has begun configuring or using the product.

Example:

`workspace_created`

---

## Adoption

Indicates increasingly meaningful or repeated product use.

Examples:

`core_workflow_created`

`core_workflow_executed`

`teammate_invited`

`usage_threshold_reached`

---

## Commercial Intent

Indicates behavior more directly associated with potential purchase or expansion.

Example:

`upgrade_intent_detected`

---

# 5. Important Business Rules

## Rule 1 — One event is not qualification

No event in this catalog automatically means that an Account is Sales Ready.

---

## Rule 2 — Intent and Fit remain separate

Product activity measures Intent.

Company characteristics determine Fit.

A high-intent Account may still be unsuitable for Sales.

---

## Rule 3 — Workspace-level behavior matters more than isolated user behavior

Revenue qualification should primarily evaluate aggregated Account or workspace behavior rather than treating every user action independently.

---

## Rule 4 — Repeated events require aggregation

Events such as `core_workflow_executed` may occur many times.

The Revenue System should summarize their meaning rather than treating each execution as a separate Sales signal.

---

## Rule 5 — Stable identifiers are required

Events should use stable product identifiers whenever possible:

* `product_user_id`
* `workspace_id`

Email and domain can assist identity resolution but should not replace stable product identifiers.

---

## Rule 6 — Event timestamp and event ID are mandatory

Each event must have:

* a unique `event_id`;
* an `occurred_at` timestamp.

These are required for traceability, ordering, and idempotency.

---

# 6. Events Intentionally Excluded

The first project version will not include every possible product event.

Events such as the following are intentionally excluded unless later requirements justify them:

* page views;
* login events;
* email opens;
* generic button clicks;
* support interactions;
* marketing engagement;
* billing events;
* customer-success events.

These events may generate noise without materially improving the initial qualification model.

---

# 7. Design Decisions Still Open

The following are intentionally deferred:

* numerical signal weights;
* rolling time windows;
* usage thresholds;
* signal decay;
* minimum combination of signals required for qualification;
* treatment of multiple users in one workspace;
* treatment of out-of-order events;
* whether specific events should expire;
* whether enrichment changes Fit dynamically.

These decisions will be finalized during Product Intent and Qualification design.
