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

Phase 6 — Jobs Listing (Free, Default View) 🔜

What this view is
	•	The first screen users see
	•	Free
	•	Always up to date
	•	Platsbanken replacement

Features
	•	Job list (latest first)
	•	Client-side filters only (no JobTech query filters):
	•	Location
	•	Occupation
	•	Employment type
	•	Scope
	•	“Ny” badge
	•	Pull-to-refresh

CV awareness
	•	If CV exists:
	•	Show CTA: “Visa CV-matchade jobb”
	•	If CV does not exist:
	•	Show CTA: “Matcha jobb med ditt CV” (teaser, locked)

No AI cost here. Ever.

⸻

Phase 7 — CV Match (Paid, Separate View) 🔜

What this view is
	•	A separate listing
	•	Based on a paid match run
	•	Frozen in time
	•	Sorted by match score

Entry points
	•	CTA from Jobs view
	•	Dedicated tab / segment (“CV-match”)

First-time flow (PAY POINT #1)
	1.	User uploads/imports CV
	2.	Profile extraction + role expansion
	3.	Profile embedding
	4.	One full CV match run against current jobs
	5.	Results shown immediately

Payment covers:
profile AI + role expansion + one CV match run

View behavior
	•	Shows:
	•	Match score per job
	•	“Why this job?” (later)
	•	Timestamp: “Matchad 30 jan”
	•	Does not auto-refresh
	•	New jobs do NOT appear here

Snapshot persistence
	•	Saved locally only
	•	Includes matches, scores, reasons, timestamp

⸻

Phase 8 — Updating CV Match (Paid Action) 🔜

When payment is required again
	•	User explicitly taps “Uppdatera CV-match”

Triggers:
	•	Re-run embeddings for jobs
	•	Re-rank
	•	Replace CV Match snapshot

This is PAY POINT #2.

No background costs. No surprises.

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
	•	✅ Client-side filters only for job lists
