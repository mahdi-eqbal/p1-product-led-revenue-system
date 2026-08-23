# Project 1 — Logical Data Model

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines the logical entities, identifiers, relationships, and data boundaries used by Project 1.

The model intentionally separates:

* product identity;
* CRM identity;
* raw product events;
* derived signal state;
* Revenue business state;
* technical processing state.

Physical PostgreSQL tables and HubSpot properties will be derived from this model in later implementation gates.

---

# 2. Core Entities

The system contains seven primary logical entities:

1. Product User
2. Workspace
3. HubSpot Contact
4. HubSpot Company
5. Product Event
6. Account Signal State
7. Processing Record

HubSpot Revenue-state properties extend the Company and Contact rather than creating a separate CRM entity unless later implementation requirements justify one.

---

# 3. Product User

A Product User represents an individual person using FlowPilot.

## Primary Identifier

`product_user_id`

Example:

`usr_2041`

This identifier originates in the FlowPilot Product System and is considered stable.

## Supporting Attributes

Potential attributes include:

* email;
* first name;
* last name;
* signup timestamp;
* workspace membership.

Only attributes needed by the Revenue process should be transferred.

## CRM Relationship

A Product User should resolve to:

one authoritative HubSpot Contact.

Conceptually:

Product User

→ HubSpot Contact

The relationship is established using:

`product_user_id`

with email as supporting evidence.

---

# 4. Workspace

A Workspace represents the product-level organizational account in FlowPilot.

Multiple Product Users may belong to the same Workspace.

## Primary Identifier

`workspace_id`

Example:

`ws_873`

## Supporting Attributes

Possible attributes include:

* workspace name;
* associated business domain;
* workspace-created timestamp;
* product-plan context where relevant.

## CRM Relationship

A Workspace should resolve to:

one authoritative HubSpot Company.

Conceptually:

Workspace

→ HubSpot Company

The relationship is established primarily through:

`workspace_id`

with Company domain as supporting evidence.

---

# 5. HubSpot Contact

A HubSpot Contact represents the CRM identity of a person.

## Primary CRM Identifier

HubSpot Contact Record ID.

## Cross-System Identifier

`product_user_id`

will be stored as a unique product-identity property where supported by the implementation.

## Relevant Responsibilities

The Contact may expose:

* CRM identity;
* email;
* Contact information;
* Product User ID;
* associated Company;
* Sales owner where appropriate;
* selected Revenue context.

The Contact does not store the full product-event history.

---

# 6. HubSpot Company

A HubSpot Company represents the primary Account-level Revenue entity.

Project 1 evaluates qualification primarily at the Company / Workspace level.

## Primary CRM Identifier

HubSpot Company Record ID.

## Cross-System Identifier

`workspace_id`

will represent the corresponding FlowPilot Workspace.

## Relevant Responsibilities

The Company will eventually expose Revenue-facing information such as:

* Company domain;
* employee count;
* country / commercial region;
* business type / industry;
* ICP Fit state;
* Product Intent state;
* Data Readiness state;
* qualification state;
* qualification reason;
* routing target;
* suppression state;
* handoff state;
* SLA state.

Exact properties will be defined during HubSpot CRM design.

---

# 7. Product Event

A Product Event represents one immutable or append-only product action received by the Revenue System.

Examples:

* `signup_completed`
* `workspace_created`
* `integration_connected`
* `upgrade_intent_detected`

## Primary Identifier

`event_id`

Example:

`evt_10001`

The identifier must be unique.

## Core Relationships

A Product Event belongs to:

one Product User

and, when applicable:

one Workspace.

Therefore:

Product User

1 → many

Product Events

and:

Workspace

1 → many

Product Events.

## Core Logical Attributes

A Product Event requires concepts equivalent to:

* `event_id`
* `event_type`
* `occurred_at`
* `product_user_id`
* `workspace_id`
* event-specific properties
* received timestamp

The raw event must remain separate from derived Product Intent state.

---

# 8. Account Signal State

Account Signal State represents the current derived interpretation of recent product activity for a Workspace.

Unlike Product Events, this entity is not raw evidence.

It is recalculated from Product Events.

## Logical Key

`workspace_id`

One Workspace should have one current Account Signal State for the active qualification model.

## Logical Attributes

The entity is expected to contain concepts equivalent to:

* `workspace_id`
* current Intent score;
* current Intent state;
* commercial-intent indicator;
* important signal summary;
* latest meaningful signal timestamp;
* calculation timestamp;
* calculation/model version.

## Relationship

Workspace

1 → 1 current Account Signal State

while:

Workspace

1 → many Product Events.

This separation allows the derived state to change without modifying source events.

---

# 9. Processing Record

A Processing Record represents the technical execution state associated with event processing.

It is not the same as Product Event data and not the same as Revenue qualification.

## Purpose

It provides durable operational evidence for:

* processing status;
* failure state;
* retry behavior;
* CRM identifiers discovered during processing;
* completion timestamps;
* relevant error details.

## Relationship

A Product Event may have:

one or more processing attempts.

Conceptually:

Product Event

1 → many Processing Records

This is important because one event may initially fail and later be safely retried.

The raw event itself should not be duplicated just because another processing attempt occurred.

---

# 10. Identity Mapping

The implementation may maintain an operational identity mapping between Product IDs and CRM IDs.

Conceptually:

`product_user_id`

↔

HubSpot Contact ID

and:

`workspace_id`

↔

HubSpot Company ID

This mapping improves integration efficiency and traceability.

However:

HubSpot remains authoritative for CRM record identity.

The Product System remains authoritative for Product User and Workspace identity.

---

# 11. Primary Account-Level Model

Revenue qualification is primarily Account-level.

Therefore the central business entity is:

Workspace / HubSpot Company.

Signals from multiple Product Users may contribute to the same Account.

Example:

User A:

`integration_connected`

User B:

`teammate_invited`

User C:

`core_workflow_executed`

All three users belong to:

`workspace_id = ws_873`

The Revenue System aggregates those signals into the Account Signal State for:

`ws_873`

rather than producing three independent Sales qualifications.

---

# 12. Contact-to-Workspace Cardinality

Version 1 assumes:

a Product User belongs to one primary Workspace for the qualification scenario.

However, the architecture should avoid unnecessarily assuming that this must always remain true.

Future product versions could allow:

one Product User

→ multiple Workspaces.

For Project 1, qualification processing will use the Workspace explicitly supplied by the event.

This keeps Account context deterministic.

---

# 13. Workspace-to-Company Cardinality

The desired authoritative mapping is:

one Workspace

→ one HubSpot Company.

A single Workspace mapping to multiple Companies is an identity conflict and must trigger review.

The system must not silently create a many-to-many Revenue identity relationship.

---

# 14. Contact-to-Company Relationship

A HubSpot Contact may theoretically have multiple Company associations.

For the Revenue qualification flow, the system needs to identify the Company corresponding to the Workspace that produced the signal.

Therefore:

workspace identity

takes precedence over blindly using any existing Contact–Company association.

Where appropriate, the authoritative Company should become or remain the appropriate primary business association.

Exact association behavior will be finalized during HubSpot implementation.

---

# 15. Qualification Location

Qualification is evaluated primarily against the Account / Company.

This means:

Product Users produce signals.

Signals aggregate to Workspace.

Workspace resolves to HubSpot Company.

Company receives Revenue qualification.

A Contact remains important for:

* identity;
* Sales communication;
* handoff context;

but individual Contact behavior does not independently create a separate Account qualification when users belong to the same Workspace.

---

# 16. Revenue State

The following concepts are Company-level Revenue state unless later implementation requirements justify otherwise:

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
* SLA status.

This Account-level design prevents several Contacts from the same Workspace from independently generating duplicate qualification processes.

---

# 17. Business State vs. Audit State

HubSpot Company stores the current Revenue-facing state.

PostgreSQL may store historical or processing evidence.

Example:

Current HubSpot qualification:

`sales_ready`

Historical operational records may show:

`monitoring`

→ `pql_candidate`

→ `sales_ready`

Those historical values must not be mistaken for competing current truth.

---

# 18. Logical Relationship Summary

The primary logical model is:

Product User

→ belongs to Workspace

Product User

→ resolves to HubSpot Contact

Workspace

→ resolves to HubSpot Company

Product User

→ generates Product Events

Workspace

→ accumulates Product Events

Product Events

→ produce Account Signal State

Account Signal State

*

HubSpot Company Context

→ produce Qualification

Qualification

→ produces Routing / Handoff state in HubSpot

Product Event

→ has Processing Records

---

# 19. Identifier Strategy

The architecture uses three classes of identifiers.

## Product Identifiers

* `product_user_id`
* `workspace_id`
* `event_id`

Generated outside the CRM.

---

## CRM Identifiers

* HubSpot Contact ID
* HubSpot Company ID

Generated by HubSpot.

---

## Operational Identifiers

PostgreSQL may use internal primary keys for database efficiency and referential integrity.

These internal IDs must not replace business identifiers such as:

`event_id`

or:

`workspace_id`

when communicating across systems.

---

# 20. No Composite Identity Guessing

The architecture must not construct an authoritative identity using an unstable combination such as:

`email + company_name`

when stable product identifiers exist.

Fallback matching may assist initial resolution, but once a stable Product-to-CRM mapping is established, that mapping becomes the preferred operational path.

---

# 21. Data Model Design Principles

## Account-level qualification

Qualification is centered on Workspace / Company.

## Raw events are preserved

Derived states do not replace source evidence.

## Processing attempts are separate

Retries do not create duplicate raw events.

## Cross-system IDs are explicit

Product and CRM identities remain traceable.

## Relationships are business-driven

Database relationships exist because the Revenue process needs them, not merely because the tools allow them.

## Current and historical state are distinct

Current CRM business state must not be confused with historical processing records.

---

# 22. Logical Model Success Criteria

The logical model must support:

1. multiple events per Product User;
2. multiple events per Workspace;
3. multiple Product Users contributing to one Workspace;
4. stable Product User → Contact resolution;
5. stable Workspace → Company resolution;
6. Account-level signal aggregation;
7. Account-level qualification;
8. multiple processing attempts for one event;
9. duplicate-event prevention;
10. end-to-end event-to-CRM traceability.
