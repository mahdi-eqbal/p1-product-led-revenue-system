## System Purpose

This project implements an end-to-end product-led revenue qualification and sales handoff system for a synthetic B2B SaaS environment.

The system converts product usage and signup signals into account-level qualification, routing, and controlled sales handoff decisions.

## Architecture

- HubSpot: CRM and revenue-facing system of record
- PostgreSQL / Supabase: product events, identity mapping, derived signal state, and processing audit trail
- n8n: workflow orchestration and API coordination
- JavaScript: deterministic scoring, ICP Fit, Data Readiness, qualification, and routing logic

## Core Processing Flow

Product Event
→ Validation
→ Durable Event Persistence
→ Duplicate Detection
→ Processing Attempt
→ Identity Resolution
→ 30-Day Rolling Product Intent Scoring
→ ICP Fit
→ Data Readiness
→ Qualification Decision
→ Existing Handoff Guard
→ Active Deal Guard
→ Routing
→ Sales Task Creation
→ CRM Associations
→ Handoff Completion
→ Processing Completion

## Reliability and Control Layer

The implementation includes:

- Authenticated webhook ingress
- Invalid-event rejection
- Database constraints
- Event-level idempotency
- Explicit duplicate handling
- Durable processing attempts
- Contact and Company identity fallback
- Identity cache persistence
- Unresolved and ambiguous identity review paths
- Existing completed-handoff protection
- Active Deal suppression
- Failure persistence and controlled retry testing
- Operational audit state in PostgreSQL

## Portfolio Context

FlowPilot, Northstar Labs, and the records used in this project are synthetic.

This project is an independently designed and implemented professional Revenue Systems case study. It does not represent a client engagement, employer deployment, production implementation, or claimed commercial revenue result.
