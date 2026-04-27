True Platsbanken — Build Plan (v2, Paid CV Match)

Product framing (important)

This app has two different products inside it:
	1.	Jobs browser (free, live, Platsbanken replacement)
	2.	CV Match (paid, frozen snapshot, AI-powered)

They are intentionally separate.

⸻

Phase 0 — Architecture ✅ DONE

No change.
	•	Stateless backend
	•	Clean separation (readers / domain / orchestrators)
	•	Single OpenAI transport
	•	Frontend = thin client
	•	Local-only persistence
	•	No accounts yet

⸻

Phase 1 — Job data correctness ✅ DONE

No change.

Trust layer is solid.

⸻

Phase 2 — Profile signals (deterministic) ✅ DONE

No change.

Used as scaffolding for AI and explanations.

⸻

Phase 3 — AI: Profile understanding ✅ DONE

No change.
	•	CV → structured profile
	•	Role expansion
	•	Strict JSON
	•	Backend only

⸻

Phase 4 — AI: Semantic matching (backend) ✅ DONE

No change.
	•	Embeddings
	•	Cosine similarity
	•	Ranking
	•	Explainability hooks

⸻

Phase 5 — Frontend ↔ Backend wiring ✅ DONE

Includes:
	•	Jobs fetch via backend
	•	Profile extraction
	•	Role expansion
	•	Match endpoint
	•	Profile embedding cache (Option B)

⸻

Phase 6 — Jobs Listing (Free, Default View) ✅ DONE

What this view is
	•	The first screen users see
	•	Free
	•	Always up to date
	•	Platsbanken replacement

Features (updated)
	•	Job list (latest first)
	•	Server-side search + filters via JobTech:
	•	Free-text search (q=) with autocomplete suggestions
	•	Filters (ID-based): location, occupation field, employment type, scope
	•	OR within filter type, AND across filter types
	•	Pull-to-refresh
	•	Infinite scroll pagination (offset/limit)
	•	Recent searches (last 3)

CV awareness
	•	If CV exists:
	•	Show CTA: “Visa CV-matchade jobb”
	•	If CV does not exist:
	•	Show CTA: “Matcha jobb med ditt CV” (teaser, locked)

No AI cost here. Ever.

⸻

Phase 7 — CV Match (Paid, Separate View) ✅ DONE

What this view is
	•	A separate listing (Matches tab)
	•	Based on a paid match run
	•	Frozen in time
	•	Sorted by match score

Entry points (updated)
	•	Home/Profile tab is first
	•	Hero marketing card at top with “Upload CV”
	•	Demo overlay still exists in Matches tab

Paid flow (implemented)
	1.	User uploads/imports CV (photo or file) from Home or overlay
	2.	Local validation only (type + size + non-empty)
	3.	Dedicated payment screen
	4. AI pipeline runs only after payment:
		•	OCR / text extraction
		•	Profile extraction + role expansion
		•	Profile embedding
		•	Match run
	5. Results saved + shown

Important constraints
	•	No pre-extraction or pre-embedding
	•	Raw CV never persisted
	•	Paid access window is local and time-bound (`paidUntil`, currently 7 days)
	•	Daily updates are on-device only and run only while entitled
	•	Failure view allows retry without re-paying (same session)
	•	Payment is still stubbed (StoreKit later)

View behavior (updated)
	•	Demo: overlay blocks job details
	•	Live: job details are tappable
	•	Match count shown on Home
	•	Match request limit currently 30

Snapshot persistence (updated)
	•	Saved locally only
	•	Used to restore live mode after restart
	•	Demo reader is not used once a live snapshot exists

⸻

Phase 8 — Match Quality (Job Pool Tailoring) ✅ DONE (Track A)

Goal
	•	Increase match quality by tailoring the job pool to the profile
	•	Reduce irrelevant matches before embeddings

Reference
	•	See JOB_MATCH_EXPANSION_PLAN.md for the two-track plan (Phase 8 ship-now + graph-based upgrade).

Delivered in Track A
	•	Resolve extracted roles/inferred roles to **JobTech occupation IDs** (canonical)
	•	Use occupation IDs first for pool fetch; fallback to `q=` only for unmapped roles
	•	Deterministic neighbor expansion from JobTech taxonomy (same field), capped (`K=2`, depth 1)
	•	Pool limits and dedupe before ranking (`~40/occupation`, `~200 total`)
	•	Diagnostics logging (role resolution, expansion, counts, final pool size)
	•	Store/reuse occupation IDs in profile snapshot

Track B (graph expansion) remains future work
	•	Skill-graph expansion and explainability layer are postponed after shipping.

⸻

Phase 8.5 — On-Device Daily Refresh (Entitled Users) ✅ DONE

Goal
	•	Keep matches fresh without storing profiles/match state on backend.

Delivered
	•	On app launch and Matches appear: update only if `lastMatchRun >= 24h`
	•	BGAppRefresh fallback task (`com.trueplatsbanken.matchrefresh`)
	•	Single-run lock to prevent concurrent expensive runs
	•	Local timestamps/lock state (`lastMatchRun`, `matchUpdateInProgress`, `lockStartedAt`)
	•	No pull-to-refresh requirement for Matches

Rules
	•	Refresh runs only in live mode, non-demo profile, and with active entitlement.
	•	Cached matches remain visible even when entitlement is expired.

⸻

Phase 9 — UX that sells the AI 🔄 IN PROGRESS

Only surfacing, no new intelligence:
	•	Match score badges ✅
	•	Show inferred roles (collapsed) ✅
	•	Shared visual language across Profile/Matches/Jobs ✅
	•	“Matched because…” bullets (optional; not required for release)
	•	Clear separation:
	•	“Live jobs”
	•	“CV-matched jobs”

⸻

Phase 10 — Accounts 🔜 LATER

Required before Phase 11.
This is not just UI prep.

Notes:
	•	Account tab placeholder can be introduced earlier (Phase 6) for layout validation.
	•	Backend persistence is still deferred until this phase.

⸻

Phase 11 — Payments (Production StoreKit) 🔜 LATER

Requires Phase 10.

Notes:
	•	Current app has stubbed payment flow + local entitlement window (7 days).
	•	This phase is about replacing stubs with production StoreKit + policy hardening.
	•	Payment implementation (planned production):
	•	iOS In-App Purchase (StoreKit 2)
	•	Non-consumable or subscription TBD (start with single CV-match run as consumable)
	•	Client-side gating first, receipt validation added when backend persistence is introduced

⸻

Phase 12 — Ship 🚀
	•	App Store copy
	•	Pricing clarity
	•	Iterate based on usage

⸻

Key decisions locked (important)
	•	❌ One combined job list → rejected
	•	✅ Two lists → required
	•	❌ Server-side cron/scheduler for matches
	•	✅ On-device daily refresh (while entitled) for existing paid profile
	•	✅ Explicit paid run required to create/replace profile snapshot
	•	✅ CV match is a product, not a filter
	•	✅ Server-side search + filters for job lists (JobTech queries)
