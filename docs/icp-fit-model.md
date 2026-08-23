# Project 1 — ICP Fit Model

## End-to-End Product-Led Revenue Qualification & Sales Handoff System

## 1. Purpose

This document defines how FlowPilot evaluates whether a Company is a commercially appropriate target for Sales.

ICP Fit is evaluated independently from Product Intent.

Product activity answers:

> How much buying or adoption intent is the Account showing?

ICP Fit answers:

> Is this the type of Account FlowPilot should actively pursue?

A Company must satisfy both dimensions before automatic Sales handoff is allowed.

---

## 2. Target Customer Profile

FlowPilot primarily targets organizations that:

* operate repeatable business processes;
* have multiple employees collaborating across workflows;
* use cloud-based business software;
* benefit from workflow automation or system integration;
* are large enough to justify a sales-assisted motion;
* operate in supported commercial regions.

The initial ICP is designed for B2B SaaS and technology-enabled companies, but the model is based on business characteristics rather than industry label alone.

---

# 3. Fit Dimensions

The initial Fit model evaluates four dimensions.

## Dimension A — Company Size

Company size acts as a proxy for process complexity, team collaboration, and potential commercial value.

| Employee Count | Fit      |
| -------------- | -------- |
| 20–199         | Strong   |
| 200–999        | Strong   |
| 10–19          | Moderate |
| 1–9            | Weak     |
| 1,000+         | Review   |

### Rationale

Very small organizations may have insufficient operational complexity for a sales-assisted motion.

Very large organizations may be valuable but may require enterprise capabilities or procurement processes outside the initial FlowPilot motion.

They should therefore be reviewed rather than automatically rejected.

---

## Dimension B — Business / Operational Fit

### Strong Fit

The Company demonstrates a clear need for:

* workflow automation;
* cross-team process coordination;
* system integration;
* repeatable operational processes.

Examples include:

* B2B SaaS;
* software companies;
* technology-enabled professional services;
* digital operations businesses.

### Moderate Fit

The Company appears to have team-based operational processes but the need for FlowPilot is not yet clear.

### Weak Fit

The organization appears primarily individual, consumer-oriented, or lacks a meaningful team workflow use case.

---

## Dimension C — Geographic Fit

### Primary Supported Regions

* United States
* Canada
* United Kingdom
* European Economic Area

Accounts in these regions can proceed through normal qualification.

### Secondary / Review Regions

Other commercially supportable regions may enter a review state rather than automatic Sales handoff.

### Unsupported

Accounts in regions where FlowPilot cannot currently support the commercial relationship must not be automatically handed to Sales.

The actual commercial region policy is treated as a business constraint rather than inferred from user location alone.

---

## Dimension D — Organizational Readiness

Signals that strengthen organizational Fit include:

* use of a business-domain email;
* multiple users associated with the same workspace;
* identifiable Company domain;
* use of external business integrations;
* team collaboration inside the product.

A single individual using a personal email address with no identifiable Company should not automatically become Sales Ready.

---

# 4. Hard Disqualifiers

The following conditions block automatic Sales qualification regardless of Product Intent:

* known test or internal Account;
* clearly invalid or disposable Company identity;
* unsupported commercial region;
* personal-use workspace with no identifiable business Account;
* explicitly suppressed Company;
* known duplicate Account requiring resolution.

A disqualified Account can still generate product activity, but the activity must not create an automatic Sales handoff.

---

# 5. Initial Fit Classification

The system will use four initial Fit states:

## `strong_fit`

The Company clearly matches the target customer profile.

---

## `moderate_fit`

The Account appears potentially suitable but does not satisfy all preferred criteria.

Strong Product Intent may move this Account into manual review.

---

## `weak_fit`

The Account does not currently match the primary commercial profile.

High Product Intent alone does not create an automatic handoff.

---

## `disqualified`

A hard exclusion rule prevents Sales qualification.

---

# 6. Initial Deterministic Fit Logic

The first implementation will use transparent business rules rather than a machine-learning model.

A Company can be classified as `strong_fit` when:

* it operates in a supported region;
* it has a valid business identity;
* it falls within the preferred company-size range;
* it demonstrates a relevant operational/team use case;
* no disqualifier exists.

A Company can be classified as `moderate_fit` when:

* no hard disqualifier exists;
* most ICP criteria are satisfied;
* one important Fit dimension remains uncertain or outside the preferred range.

A Company becomes `weak_fit` when:

* no hard disqualifier exists;
* multiple important ICP characteristics do not match the target profile.

A Company becomes `disqualified` whenever a hard exclusion rule is triggered.

---

# 7. Fit Data Requirements

The Fit evaluation may require the following Company attributes:

* `company_name`
* `company_domain`
* `employee_count`
* `country`
* `industry`
* `business_type`
* `account_segment`
* `is_internal_account`
* `is_suppressed`

Not every field must originate from the same system.

The Source-of-Truth Matrix will later define ownership for each attribute.

---

# 8. Unknown Data Handling

Missing Fit information must not automatically be interpreted as poor Fit.

For example:

`employee_count = unknown`

does not mean:

`weak_fit`

Instead, insufficient information may result in:

`moderate_fit`

or:

`needs_review`

depending on the qualification context.

This distinction prevents missing data from being confused with negative evidence.

---

# 9. Fit vs. Intent Examples

## Example A

Company:

* 120 employees
* B2B SaaS
* United Kingdom
* valid business domain

Product activity:

* signup only

Result:

**Strong Fit / Low Intent**

The Account remains under monitoring.

---

## Example B

Company:

* 80 employees
* supported geography
* strong operational use case

Product activity:

* workspace created
* integration connected
* multiple workflow executions
* teammates invited

Result:

**Strong Fit / High Intent**

This may become Sales Ready if data-readiness requirements are also satisfied.

---

## Example C

Company:

* 3 employees
* unclear business use case

Product activity:

* very high usage

Result:

**Weak Fit / High Intent**

The system must not automatically create a Sales handoff solely because Product Intent is high.

---

## Example D

Company:

* 250 employees
* strong operational profile
* unsupported commercial region

Product activity:

* very high usage
* upgrade intent detected

Result:

**Disqualified / High Intent**

Automatic Sales handoff remains blocked.

---

# 10. Design Principles

## Fit is explainable

Revenue Operations must be able to identify which criteria produced the Fit classification.

## Missing data is not negative data

Unknown information must be represented explicitly.

## Hard disqualifiers override scoring

Certain business constraints cannot be compensated for by Product Intent.

## Fit rules remain configurable

The initial rules are implementation assumptions for this case study and should be changeable without redesigning the entire integration architecture.

---

# 11. Open Decisions

The following will be finalized later:

* whether Fit uses an internal numerical score in addition to the categorical state;
* enrichment provider, if one is required;
* exact treatment of 1,000+ employee Accounts;
* exact secondary-region policy;
* whether Industry is required or merely supporting evidence;
* how frequently Company Fit should be recalculated;
* what happens when enrichment data changes after Sales handoff.
