# Project 1 — Architecture Diagrams

This directory contains the visual architecture specifications for the End-to-End Product-Led Revenue Qualification & Sales Handoff System.

## System Architecture

Source:

`system-architecture.mmd`

Purpose:

Shows system boundaries and responsibility allocation across:

* FlowPilot Product System
* n8n
* PostgreSQL / Supabase
* HubSpot

The diagram emphasizes the separation between raw product-event data, orchestration logic, operational state, and CRM-facing Revenue state.

## End-to-End Data Flow

Source:

`end-to-end-data-flow.mmd`

Purpose:

Shows the runtime lifecycle of a product event from ingestion through:

* authentication;
* validation;
* idempotency;
* identity resolution;
* product-signal aggregation;
* qualification;
* routing;
* Sales handoff;
* failure handling;
* SLA initialization.

## Publication Strategy

Mermaid source files remain version-controlled as the canonical diagram sources.

During Portfolio Packaging, approved diagrams can be exported to SVG or PNG and adapted for:

* GitHub README;
* technical Case Study;
* portfolio presentation;
* LinkedIn project assets;
* recruiter or client walkthroughs.
