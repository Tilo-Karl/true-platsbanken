Multi-Track Plan — Job Expansion Architecture (v4)

Purpose
Improve CV-match quality by:
- keeping job-pool retrieval deterministic and taxonomy-based
- upgrading role expansion from synonym generation to cross-domain employability inference
- separating core-role matching from capability-family pivot matching

Pipelines in production:
- Core:
  CV -> AI profile extraction -> role expansion -> role -> occupation resolver -> job pool builder -> embeddings ranking
- Pivot:
  CV/profile signals -> CandidateOpportunityProfile -> pivot opportunity families -> pivot job pool -> embeddings ranking

---

Track A — Implemented Baseline (Phase 8 Ship-Now)

Goal
Reduce irrelevant jobs before embeddings by using JobTech occupations as canonical IDs.

Delivered
1. Role -> Occupation Resolver
- Roles and inferred roles are resolved to JobTech occupation IDs via taxonomy + fuzzy scoring.
- Unmapped roles fall back to free-text `q=` search.

2. Occupation IDs in Snapshot
- Snapshot includes:
  - roles
  - inferredRoles
  - occupationIds
  - profile embedding

3. Job Pool Builder
- Uses occupation IDs first.
- Process:
  occupationIds -> small neighbor expansion -> JobTech queries -> merged pool

4. Neighbor Expansion
- Deterministic from JobTech field proximity.
- `K = 2`, depth `1` (no recursion).

5. Pool Limits
- max jobs/occupation: ~40
- max total pool: ~200
- dedupe before ranking

6. Diagnostics
- Logs role resolution, expanded occupation set, per-occupation counts, final deduped size.

Result
Track A is stable and production-usable, but inferred-role breadth is still too narrow.

---

Track A+ — Role Expansion v2 ✅ DONE

Problem solved
Current inferred roles are often near-duplicates of explicit roles and do not surface adjacent career families.

Delivered objective
Rewrite role expansion to infer cross-domain employability, not synonyms.

Role expansion must infer broader families from:
- transferable skills
- leadership
- domain knowledge
- tools/platform literacy
- physical/operational work
- customer/commercial work
- coordination/planning
- technical literacy

Hard rule (implemented)
Do not return roles that are renamed versions of explicit roles.

Definition for "renamed version"
- lexical near-duplicate of an explicit role (token overlap/high similarity), or
- same canonical occupation ID as an explicit role after resolver mapping

If either condition is true:
- inferred role is rejected server-side

Output contract (implemented)
Each inferred role item must include:
- `role`
- `category`
- `confidence`
- `reason`
- `sourceSignals`

Recommended response schema
```json
{
  "inferredRoles": [
    {
      "role": "Technical Project Manager",
      "category": "Leadership & Delivery",
      "confidence": 0.82,
      "reason": "Cross-team planning and delivery ownership",
      "sourceSignals": ["backlog prioritization", "stakeholder coordination", "agile delivery"]
    }
  ]
}
```

Category set (controlled vocabulary)
- Leadership & Delivery
- Operations & Coordination
- Product & Strategy
- Customer & Commercial
- Technical & Engineering
- Service & Support
- Field & Physical Operations

Guardrails (implemented)
1. Diversity:
- Return roles across multiple categories where evidence exists.
- Avoid returning many variants in one narrow family.

2. Confidence discipline:
- low confidence roles are allowed but must still have concrete evidence in `sourceSignals`.
- no empty reasons, no empty signal arrays.

3. Explicit-role exclusion:
- never return explicit roles in inferred output.
- never return same resolved occupation ID as explicit roles.

4. Explainability:
- `reason` is concise (1 sentence).
- `sourceSignals` are evidence phrases, not generic claims.

Integration with existing pipeline
1. AI extractor returns explicit roles (as today).
2. Role expansion v2 returns inferred roles with metadata.
3. Resolver maps both explicit and inferred to occupation IDs.
4. Deduper removes inferred roles violating the hard rule.
5. Job pool builder uses canonical occupation IDs.

No backend architecture change was required.
This upgrade shipped as inference-quality + output-shape changes while preserving backward compatibility (`inferredRoles` string array).

Status
- completed
- active for deployed backend revisions

Remaining tuning
- category diversity tuning by profile type
- confidence threshold tuning by observed quality

---

Track C — Opportunity Profile + Dual Match Pools ✅ DONE (Inspection Baseline)

Goal
Split matching output into:
- core matches (close to current profile)
- pivot matches (capability-family driven alternatives)

Delivered
1. Candidate Opportunity Profile (new backend concept)
- includes:
  - primaryDomains
  - secondaryDomains
  - transferableCapabilities
  - workEnvironments
  - careerStage
  - coreOccupationTargets
  - pivotOpportunityFamilies
  - lowLeverageFamilies

2. Dual pool build
- Core pool: existing occupation-based path
- Pivot pool: generated from `pivotOpportunityFamilies` (occupation seeds + search terms)
- Pivot jobs tagged at source with pivot family metadata

3. Match API shape (backward-compatible extension)
- `/api/match` returns:
  - `matches` (combined)
  - `coreMatches`
  - `pivotMatches`
  - `coreCount`
  - `pivotCount`
  - `opportunityProfile`

4. Pivot family assignment + balancing
- Pivot matches carry `pivotFamily`
- Final pivot list uses round-robin family balancing
- Prevents single-family dominance until smaller families are exhausted

5. Inspection UI support
- Matches view grouped into:
  - Best CV matches
  - Career pivots
- Pivot cards show `Pivot` badge
- Profile includes temporary “Opportunity profile” debug section

Status
- deployed baseline is active
- further ranking tuning remains product-quality iteration, not architecture gap

---

Track B — Graph Expansion (Post-Ship Upgrade)

Goal
Replace simple neighbor expansion with skill-graph expansion for deeper discovery and stronger explanations.

Architecture
Occupation <-> Skill <-> Occupation graph (JobTech-based signals)

Track B replaces only:
job pool expansion logic

Everything else remains:
CV extraction -> role expansion -> occupation resolution -> ranking

Benefits
- richer adjacency paths
- skill-grounded exploration
- better "why this match" explanations

---

Relationship between tracks

Track A:
deterministic, low risk, shipping baseline

Track A+:
higher-quality inferred roles (cross-domain employability)

Track C:
capability-family pivots with dual core/pivot match outputs

Track B:
future graph-based pool expansion

All tracks are compatible.
Track B remains optional future depth on top of the current shipped baseline (A + A+ + C).
