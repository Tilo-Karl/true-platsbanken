Two-Track Plan — Job Expansion Architecture (v3)

Purpose
Improve CV-match quality by:
- keeping job-pool retrieval deterministic and taxonomy-based
- upgrading role expansion from synonym generation to cross-domain employability inference

The matching pipeline remains:
CV -> AI profile extraction -> role expansion -> role -> occupation resolver -> job pool builder -> embeddings ranking

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

Track A+ — Role Expansion v2 (Immediate Next)

Problem to solve
Current inferred roles are often near-duplicates of explicit roles and do not surface adjacent career families.

New objective
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

Hard rule
Do not return roles that are renamed versions of explicit roles.

Definition for "renamed version"
- lexical near-duplicate of an explicit role (token overlap/high similarity), or
- same canonical occupation ID as an explicit role after resolver mapping

If either condition is true:
- reject that inferred role

Output contract (required)
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

Guardrails
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

No backend architecture change is required.
This is an upgrade of inference quality + output shape.

Success criteria
- fewer near-duplicate inferred roles
- broader but relevant occupation coverage
- improved top-N relevance in matches
- explainable inferred-role output

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

Track B:
future graph-based pool expansion

All three are compatible.
Track A+ can be delivered before Track B and will already improve quality materially.
