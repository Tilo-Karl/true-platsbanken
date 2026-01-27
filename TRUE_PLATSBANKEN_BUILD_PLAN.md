True Platsbanken — Build Plan (Stateless Backend)

⸻

Phase 0 — Architecture ✅ DONE

Goal: sane foundation
Status: ✔ Complete
	•	Backend split into readers / domain / orchestrators
	•	Frontend split into Views / ViewModels / Services
	•	External adapters isolated (JobTech, OpenAI, Backend API)
	•	Clean-code rules enforced and audited
	•	Single OpenAI transport reader
	•	Prompts treated as data, owned by domain
	•	No duplicate invariants across files

This is solid and stays.

⸻

Phase 1 — Job data correctness ✅ DONE

Goal: users trust the app immediately
Status: ✔ Complete
	•	Job model aligned with JobTech
	•	Correct:
	•	vacancies
	•	employment type
	•	duration
	•	scope of work
	•	deadline
	•	occupation label
	•	Reader-only mapping
	•	UI mirrors Platsbanken
	•	Employer field fixed
	•	“Ny” badge + timestamps correct
	•	Europe/Stockholm day handling correct
	•	Localization:
	•	Central AppStrings
	•	sv / en
	•	Language toggle works

Trust achieved. Move on.

⸻

Phase 2 — Profile signals (Deterministic) ✅ DONE

Goal: structure before intelligence
Status: ✔ Complete

What exists and is used:
	•	Input:
	•	CV text (raw)
	•	skills text
	•	employment preferences
	•	Output:
	•	keywords
	•	occupations
	•	locations
	•	seniority hints
	•	constraints
	•	Implementation:
	•	extractProfileSignals
	•	deterministic
	•	no AI
	•	Used by:
	•	embedding text construction
	•	match explanations
	•	constraints
	•	fallback structure

This is not a fallback for AI.
It is signal scaffolding.

Mark done.

⸻

Phase 3 — AI v1: Profile understanding ✅ DONE

Goal: turn CV → structured profile
Status: ✔ Complete
	•	/api/profile/extract
	•	AI extracts:
	•	keywords
	•	roles
	•	seniority
	•	locations
	•	summary
	•	/api/profile/expand-roles
	•	AI infers adjacent roles
	•	rationale included
	•	Strict JSON enforced
	•	Stateless
	•	Backend-only
	•	No frontend changes required

AI is alive.

⸻

Phase 4 — AI v1: Semantic matching ✅ DONE (backend)

Goal: real matching, not filters
Status: ✔ Backend complete
	•	Embeddings:
	•	profile text
	•	job text
	•	Cosine similarity
	•	Deterministic ranking layer
	•	Explainability hooks (“matched on”)
	•	No heuristics in UI
	•	Backend owns intelligence

What’s missing is frontend wiring, not logic.

⸻

Phase 5 — Frontend ↔ Backend wiring (no persistence) 🔜 NEXT

Goal: frontend becomes a thin client
Status: 🚧 Next

Required changes (no AI changes):
	•	Frontend stops:
	•	fetching JobTech directly
	•	calling Firestore
	•	Frontend starts:
	•	GET /api/jobs
	•	POST CV → /api/profile/extract
	•	POST profile → /api/profile/expand-roles
	•	POST profile + jobs → /api/match
	•	Persist profile locally only (UserDefaults / file)
	•	ViewModels updated to consume:
	•	MatchResult { job, score, reasons }

This is now the critical path.

⸻

Phase 6 — UX that sells the AI 🔜 NEXT+

Goal: user understands why
Status: Planned
	•	Match score indicator
	•	“Why this job?” view
	•	Show inferred roles (toggleable)
	•	Profile improvement hints
	•	No new intelligence — just surfacing what exists

⸻

Phase 7 — Hardening & cleanup 🔜 LATER

Goal: remove scaffolding
Status: Planned
	•	Remove dev paths
	•	Lock prod config
	•	Rate limiting
	•	Caching
	•	Pagination

⸻

Phase 8 — Ship 🚀

Goal: real users
Status: Planned
	•	App Store copy
	•	Analytics after value is proven
	•	Iterate based on usage, not theory

⸻

Clarified architecture (v1)
	•	Backend is stateless
	•	No Firestore
	•	No accounts/auth/consent/payments
	•	No schedulers
	•	Backend owns JobTech fetching + normalization
	•	Frontend stores profile locally only
