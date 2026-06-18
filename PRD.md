# Home Vault - Product Requirements Document (PRD)

## Vision

Home Vault is an AI-powered household inventory management application that helps users track expiry dates, warranties, invoices, and important household items from a single place.

The initial MVP focuses on expiry tracking and reminder notifications while building a scalable foundation for warranty and inventory management.

---

# Problem Statement

Consumers frequently forget:

* Product expiry dates
* Medicine expiry dates
* Food expiry dates
* Warranty expiration dates
* Invoice locations

This results in:

* Wasted products
* Health risks
* Lost warranty claims
* Poor household organization

Home Vault solves this through AI-powered scanning, OCR extraction, and proactive reminders.

---

# Target Users

Primary Users:

* Families
* Parents
* Working professionals
* Elderly users

Secondary Users:

* Small clinics
* Pharmacies
* Home businesses

---

# Success Metrics

MVP Goals:

* 100 downloads
* 50 registered users
* 500 scanned items
* 30% weekly retention

Version 2 Goals:

* 1000 users
* 5000 stored items
* 10 paid subscribers

---

# Core Features (MVP)

## User Authentication

* Email Login
* Google Login
* Anonymous Guest Mode

---

## Item Management

Create Item

Fields:

* Name
* Category
* Product Photo
* Purchase Date
* Expiry Date
* Notes

Actions:

* Add
* Edit
* Delete
* Archive

---

## OCR Scanner

User takes product photo.

System extracts:

* Product Name
* Expiry Date

Technology:

* Google ML Kit OCR

Confidence Score:

* High
* Medium
* Low

Low confidence requires manual verification.

---

## Dashboard

Sections:

Expiring Soon

* 7 Days

Expiring This Month

* 30 Days

Expired

Recently Added

Statistics:

* Total Items
* Expiring Soon
* Expired

---

## Notifications

Reminder Rules:

* 30 days before expiry
* 7 days before expiry
* 1 day before expiry
* Expired today

Push Notifications via Firebase.

---

# Data Model

Item

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

User

* id
* email
* displayName
* plan
* createdAt

---

# Categories

Food

Medicine

Cosmetics

Baby Products

Electronics

Household

Other

---

# Version 2 Features

Warranty Tracker

Invoice Upload

PDF Storage

Warranty Expiry Notifications

Electronics Inventory

Asset Tracking

---

# Version 3 Features

AI Product Recognition

AI Auto Categorization

AI Expiry Extraction

Smart Reminder Suggestions

Natural Language Search

Examples:

"When does my AC warranty expire?"

"Show all medicines expiring next month."

---

# Monetization

Free Plan

* 10 Items
* Basic Reminders

Premium Plan

* Unlimited Items
* Family Sharing
* Invoice Storage
* Warranty Tracking
* AI Assistant

Pricing:

₹49/month

₹399/year

---

# Non Functional Requirements

App Launch Time:
< 2 seconds

OCR Processing:
< 5 seconds

Crash Free Rate:

> 99%

Supported Platforms:

Android MVP

iOS Future

---

# MVP Definition

A user can:

* Register
* Scan a product
* Extract expiry date
* Save item
* Receive reminder notification
* View expiring items dashboard

If these flows work successfully, MVP is complete.
