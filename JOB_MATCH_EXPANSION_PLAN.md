Two-Track Plan — Job Expansion Architecture

Purpose
Improve the quality of the job pool used for CV matching while keeping the system simple enough to ship quickly. The system is built so that the simple version can later be replaced by a more advanced expansion system without changing the rest of the matching pipeline.

The matching pipeline remains:
CV → AI profile extraction → role expansion → role → occupation resolver → job pool builder → embeddings ranking

Track A — Phase 8 (Ship Now)

Goal
Improve match quality immediately by replacing generic job searches with occupation-based job pools using the JobTech taxonomy.

Key idea
Resolve roles returned by AI into JobTech occupation IDs and use those IDs to fetch jobs directly instead of relying mainly on free-text search.

Steps
1. Role → Occupation Resolver
   - AI returns roles and inferred roles from the CV.
   - These role strings are resolved to JobTech occupation IDs using the JobTech taxonomy and fuzzy matching.
   - If a role cannot be mapped confidently, the system falls back to free-text job search.
2. Store Occupation IDs in the Profile Snapshot
   - The profile snapshot stored after a match run should include:
     - roles
     - inferredRoles
     - occupationIDs
     - profile embedding
   - This avoids resolving the same roles again later.
3. Job Pool Builder (Phase 8 Implementation)
   - The job pool builder uses the occupation IDs to fetch jobs from JobTech.
   - Process:
     - occupationIDs → small neighbor expansion → JobTech queries → merged job pool
4. Neighbor Expansion (Simple Version)
   - To avoid overly narrow job pools, each occupation may expand to a small number of related occupations.
   - Rules:
     - neighbors per occupation: 2
     - expansion depth: 1 (no recursive expansion)
   - Example:
     - Product Owner → Product Manager → Scrum Master
   - No further expansion beyond this.
5. Job Pool Limits
   - To keep the embedding step efficient:
     - maximum jobs per occupation: ~40
     - maximum total job pool: ~200
   - Duplicate jobs are removed before ranking.
6. Pool Diagnostics Logging
   - Log basic metrics to evaluate pool quality:
     - roles returned by AI
     - resolved occupation IDs
     - number of jobs fetched per occupation
     - final job pool size after deduplication
   - This allows comparison with the previous generic job pool approach.

Result
Phase 8 produces a more relevant job pool while keeping the system simple and deterministic.

Track B — Graph-Based Expansion (Future Upgrade)

Goal
Improve job discovery and match explanations using a skill-based occupation graph.

Key idea
Replace simple neighbor expansion with a graph built from occupation-skill relationships so that the system can discover adjacent careers and explain matches through shared skills.

Architecture
Occupation → Skill → Occupation graph

Nodes:
- occupations
- skills

Edges:
- occupation ↔ skill relationships
- derived occupation ↔ occupation similarity based on shared skills

Graph expansion replaces the Phase 8 neighbor expansion.

Process:
occupationIDs → graph walk (skill-based expansion) → expanded occupation set → JobTech queries → embeddings ranking

Additional capabilities enabled by the graph:
- skill-based explanations (“matched because you have X skills”)
- career adjacency discovery
- identification of roles requiring small retraining steps

Relationship Between Track A and Track B

Track B replaces only the Job Pool Builder expansion logic.

The rest of the system remains unchanged:
CV extraction → role expansion → role → occupation resolution → profile embedding → job ranking

Pipeline with Track A:
CV → AI profile extraction → role expansion → occupation resolver → job pool builder (simple neighbors) → embeddings ranking

Pipeline with Track B:
CV → AI profile extraction → role expansion → occupation resolver → job pool builder (graph expansion) → embeddings ranking

This ensures Phase 8 can ship quickly while keeping the architecture ready for the more advanced expansion system later.
