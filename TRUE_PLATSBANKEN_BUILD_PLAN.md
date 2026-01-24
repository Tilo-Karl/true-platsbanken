True Platsbanken  Build Plan (Restated + Status)

Phase 0  Architecture (DONE)

Goal: sane foundation
Status: 4 Complete
     Backend split into readers / writers / orchestrators
     Frontend split into Views / ViewModels / Services
     Data flows are clean, swappable, testable
     Mock  real backend swap isolated and already exercised

This phase is solid.

---

Phase 1  Data correctness (FOUNDATION)

Goal: users trust the app immediately
Status: 4 Functionally complete, with a small polish tail

Whats done:
     Job model aligned with JobTech
     numberOfVacancies
     employment_type.label
     duration.label
     scope_of_work (min/max + derived label)
     application_deadline
     occupation.label
     Mapping centralized in reader only
     List + detail layout mirrors Platsbanken closely
     Employer field mismatch resolved:
     We now use employer.workplace, matching Platsbanken
     Ny badge + timestamps fixed
     Correct parsing
     Correct Europe/Stockholm day boundaries
     Localization bonus completed
     Central AppStrings
     No hardcoded UI strings
     sv / en ready
     Language toggle wired (SwiftUI invalidation handled)

Remaining (minor, optional polish):
     Decide which additional JobTech fields to surface (not model):
     salary_description
     conditions
     working_hours_type.label
     apply link prominence

But trust-wise: this phase is done.

---

Phase 2  Profile signal extraction (NEXT)

Goal: structure before intelligence
Status:  Next phase
     Input:
     skills text
     CV text
     employment preferences
     Output:
     keywords
     occupations
     locations
     seniority hints
     Implementation:
     ProfileSignalExtractor
     pure, deterministic
     no AI, no embeddings

This is the bridge between form input and matching.

---

Phase 3  AI v1: Semantic matching

Goal: real matching, not filters
Status:  Planned
     Embeddings:
     profile text
     job description
     Similarity scoring (cosine)
     Explainability hooks (Matched on)
     Lives entirely in backend
     UI unchanged

This is where AI first appears.

---

Phase 4  Hybrid scoring

Goal: results feel obviously right
Status:  Planned
     Semantic score + hard constraints + soft boosts
     Deterministic + explainable
     Output: MatchResult { job, score, reasons }

---

Phase 5  UX that sells the AI

Goal: user understands why it works
Status:  Planned
     Match score indicator
     Why this job?
     Profile improvement feedback

---

Phase 6  Final backend wiring

Goal: no scaffolding left
Status:  Mostly already done, final sweep later
     Remove last dev-only paths
     Lock prod services

---

Phase 7  Ship

Goal: ship something people trust
Status:  Planned
     caching
     pagination
     App Store copy
     analytics after value is proven
