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
	•	Payment validity is session-only
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

Phase 8 — Match Quality (Job Pool Tailoring) 🔜

Goal
	•	Increase match quality by tailoring the job pool to the profile
	•	Reduce irrelevant matches before embeddings

Reference
	•	See JOB_MATCH_EXPANSION_PLAN.md for the two-track plan (Phase 8 ship-now + graph-based upgrade).

Approach
	•	Resolve extracted roles and inferred roles to **JobTech occupation IDs** (canonical taxonomy)
	•	Use those occupation IDs to fetch jobs from JobTech instead of relying primarily on free-text queries
	•	Expand the pool slightly using **occupation neighbors** (similar occupations derived from taxonomy proximity)
	•	Fallback to q= free-text search only when a role cannot be mapped to a JobTech occupation
	•	Run embeddings + ranking only on this tailored job pool

Notes
	•	JobTech occupations become the canonical role representation in the backend
	•	Role strings from AI are resolved to occupation IDs once and cached
	•	Occupation expansion should stay limited (small neighbor set) to avoid noisy pools

Important rule
	•	No auto-updating against new jobs
	•	New paid run only happens on explicit upload/payment
	•	No background costs

⸻

Phase 9 — UX that sells the AI 🔜

Only surfacing, no new intelligence:
	•	Match score badges
	•	“Matched because…” bullets
	•	Show inferred roles (collapsed)
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

Phase 11 — Payments 🔜 LATER

Requires Phase 10.

Notes:
	•	Payment touchpoints can be surfaced earlier as UI-only affordances.
	•	Payments gated before:
	•	CV import
	•	CV match update
	•	Backend persistence is still deferred until this phase.
	•	Payment implementation (planned):
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
	•	❌ Auto-matching new jobs → never
	•	✅ Explicit paid match runs only
	•	✅ CV match is a product, not a filter
	•	✅ Server-side search + filters for job lists (JobTech queries)
