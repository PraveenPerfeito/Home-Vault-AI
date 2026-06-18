# CLAUDE.md

# Home Vault - AI Development Rules

## Project Mission

Home Vault is an AI-powered household inventory application focused on helping users manage:

* Product Expiry Dates
* Warranty Tracking
* Home Inventory
* Invoice Storage

The primary goal is to launch a working Android MVP on the Play Store as quickly as possible.

Always prioritize shipping over perfection.

---

# Required Reading Order

Before starting ANY task, read:

1. PRD.md
2. docs/ROADMAP.md
3. docs/ARCHITECTURE.md
4. docs/DECISIONS.md
5. CLAUDE.md

Never start implementation without understanding the current project state.

---

# MVP Scope (Must Build)

## Phase 1

Foundation

* Flutter setup
* Firebase setup
* Riverpod
* GoRouter
* Theme
* Logging
* Error handling

## Phase 2

Authentication + Item CRUD

Authentication:

* Email Login
* Google Login
* Guest Login
* Logout

Item Management:

* Add Item
* Edit Item
* Delete Item
* List Items

## Phase 3

OCR Scanner

* Camera integration
* Gallery upload
* ML Kit OCR
* Expiry date extraction
* Product name extraction
* Manual correction

## Phase 4

Dashboard

* Total Items
* Expiring Soon
* Expired
* Recently Added

## Phase 5

Notifications

* 30 days before expiry
* 7 days before expiry
* 1 day before expiry
* Expired today

## Phase 6

Play Store Release

* Privacy Policy
* App Icon
* Screenshots
* Release Build
* Internal Testing

---

# Explicitly Out of Scope

Do NOT implement unless specifically requested.

* iOS Support
* Web Support
* Desktop Support
* RevenueCat
* Subscription Billing
* Premium Plans
* Family Sharing
* AI Chat Assistant
* Admin Panel
* Analytics Dashboard
* Social Features
* Multi-Tenant Architecture
* Complex Offline Sync
* Microservices
* Supabase
* Backend Servers

Keep the MVP simple.

---

# Technology Stack

Frontend:

* Flutter

State Management:

* Riverpod

Routing:

* GoRouter

Backend:

* Firebase Auth
* Firestore
* Firebase Storage
* Firebase Cloud Messaging

Local Storage:

* Hive

OCR:

* Google ML Kit

Target Platform:

* Android Only

---

# Architecture Rules

Use Feature-First Clean Architecture.

Structure:

lib/

core/
shared/

features/

auth/
items/
scanner/
dashboard/
notifications/

Each feature must contain:

data/
domain/
presentation/

Avoid creating unnecessary layers.

Keep implementations simple.

---

# Database Rules

Firestore is the source of truth.

Item Schema:

* id
* userId
* name
* category
* photoUrl
* purchaseDate
* expiryDate
* warrantyDate
* invoiceUrl
* notes
* createdAt
* updatedAt

User Schema:

* id
* email
* displayName
* plan
* createdAt

Do not modify schemas without updating documentation.

---

# Coding Standards

Prefer:

* Readable code
* Small files
* Clear naming
* Simplicity

Avoid:

* Premature optimization
* Generic frameworks
* Over-abstraction
* Unnecessary design patterns

Every dependency must have a clear reason.

---

# UI Guidelines

Use Material Design 3.

Prioritize:

* Fast navigation
* Simple forms
* Large touch targets
* Clean dashboard

Do not spend excessive effort on animations.

Functionality first.

---

# Documentation Rules

Documentation is mandatory.

After every completed phase:

Update:

docs/ROADMAP.md

Update:

* Current phase
* Completed tasks
* Remaining tasks
* Next phase

Update:

docs/ARCHITECTURE.md

Update:

* Folder structure
* Dependencies
* Database changes
* Firebase configuration
* Design decisions

Update:

docs/DECISIONS.md

Record:

* Major decisions
* Tradeoffs
* Deferred features

PRD.md should remain mostly stable.

Only update PRD.md if product requirements change.

---

# Git Workflow

After every completed phase:

1. Ensure project builds successfully
2. Ensure analyzer passes
3. Ensure tests pass
4. Update documentation
5. Commit changes

Recommended commit format:

PHASE-1 Foundation Complete

PHASE-2 Auth and CRUD Complete

PHASE-3 OCR Scanner Complete

---

# Output Requirements

At the end of every task provide:

## Summary

Completed:

* list completed items

Files Created:

* file list

Files Modified:

* file list

Dependencies Added:

* package list

Documentation Updated:

* ROADMAP.md
* ARCHITECTURE.md
* DECISIONS.md

Testing Instructions:

* commands to run

Known Issues:

* list issues

Next Recommended Phase:

* phase name

Then STOP and wait for review.

Do not continue into the next phase automatically.

---

When making a new architectural or product decision:

1. Implement the change.
2. Record the decision in docs/DECISIONS.md.
3. Explain:
   - Decision
   - Reason
   - Impact
   - Alternatives considered

---

# Golden Rule

Build the smallest working solution that satisfies the PRD.

Do not overengineer.

Do not build future features early.

Ship the MVP first.
