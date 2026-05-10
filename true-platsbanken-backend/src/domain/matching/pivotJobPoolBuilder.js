const { fetchJobsForOccupationIds, fetchJobsForQueries } = require('./jobPoolFetchers');
const {
  computePivotPerOccupationLimit,
  computePivotPerQueryLimit,
  uniquePreservingOrder,
  mergePools,
  logPoolSize
} = require('./jobPoolUtils');
const { MAX_PIVOT_POOL, MAX_PIVOT_QUERIES } = require('./jobPoolConstants');

async function buildPivotJobPool({ profile, limit, opportunityProfile, coreOccupationIds }) {
  const municipality = profile?.municipality ? String(profile.municipality).trim() : '';
  const hasMunicipality = Boolean(municipality);

  const families = Array.isArray(opportunityProfile?.pivotOpportunityFamilies)
    ? opportunityProfile.pivotOpportunityFamilies
    : [];
  if (!families.length) return [];

  const coreOccupationSet = new Set(uniquePreservingOrder(coreOccupationIds));
  const maxPool = Math.min(Math.max(limit * 6, 80), MAX_PIVOT_POOL);
  const perFamilyTarget = Math.max(12, Math.ceil(maxPool / Math.max(1, families.length)));
  const perFamilyMaxPool = Math.max(20, Math.ceil(perFamilyTarget * 1.5));

  let pool = [];
  for (const family of families) {
    const familyId = String(family?.id || '').trim();
    const familyLabel = String(family?.label || '').trim();
    if (!familyId || !familyLabel) continue;

    const familyTag = {
      id: familyId,
      label: familyLabel,
      fitScore: Number(family?.fitScore || 0)
    };
    const familyOccupationIds = uniquePreservingOrder(
      Array.isArray(family?.occupationIds) ? family.occupationIds : []
    ).filter((occupationId) => !coreOccupationSet.has(occupationId));
    const familyQueries = uniquePreservingOrder([
      ...(Array.isArray(family?.searchTerms) ? family.searchTerms : []),
      ...(Array.isArray(family?.occupationSeeds) ? family.occupationSeeds : [])
    ]).slice(0, MAX_PIVOT_QUERIES);

    const perOccupationLimit = computePivotPerOccupationLimit(familyOccupationIds.length, limit);
    const perQueryLimit = computePivotPerQueryLimit(familyQueries.length, limit);

    let familyPool = [];
    if (familyOccupationIds.length) {
      let result = await fetchJobsForOccupationIds(familyOccupationIds, {
        perOccupationLimit,
        maxPool: perFamilyMaxPool,
        municipality: hasMunicipality ? municipality : null,
        decorateJob: (job) => ({ ...job, _pivotFamily: familyTag })
      });
      familyPool = mergePools(familyPool, result.pool, perFamilyMaxPool);

      if (familyPool.length < Math.floor(perFamilyTarget * 0.5) && hasMunicipality) {
        result = await fetchJobsForOccupationIds(familyOccupationIds, {
          perOccupationLimit,
          maxPool: perFamilyMaxPool,
          municipality: null,
          decorateJob: (job) => ({ ...job, _pivotFamily: familyTag })
        });
        familyPool = mergePools(familyPool, result.pool, perFamilyMaxPool);
      }
    }

    if (familyQueries.length && familyPool.length < perFamilyTarget) {
      let queryPool = await fetchJobsForQueries(familyQueries, {
        perQueryLimit,
        maxPool: perFamilyMaxPool - familyPool.length,
        municipality: hasMunicipality ? municipality : null,
        decorateJob: (job) => ({ ...job, _pivotFamily: familyTag })
      });
      familyPool = mergePools(familyPool, queryPool, perFamilyMaxPool);

      if (familyPool.length < Math.floor(perFamilyTarget * 0.5) && hasMunicipality) {
        queryPool = await fetchJobsForQueries(familyQueries, {
          perQueryLimit,
          maxPool: perFamilyMaxPool - familyPool.length,
          municipality: null,
          decorateJob: (job) => ({ ...job, _pivotFamily: familyTag })
        });
        familyPool = mergePools(familyPool, queryPool, perFamilyMaxPool);
      }
    }

    pool = mergePivotFamilyPool(pool, familyPool, maxPool);
    logPoolSize(`pivot_family_${familyId}`, familyPool);
    if (pool.length >= maxPool) break;
  }

  logPoolSize('pivot_final', pool);
  return pool;
}

function mergePivotFamilyPool(primary, secondary, maxPool) {
  const seen = new Set(
    (Array.isArray(primary) ? primary : []).map((job) => {
      const familyId = String(job?._pivotFamily?.id || '').trim();
      return `${job?.id || ''}::${familyId}`;
    })
  );
  const merged = [...(Array.isArray(primary) ? primary : [])];

  for (const job of Array.isArray(secondary) ? secondary : []) {
    if (!job || !job.id) continue;
    const familyId = String(job?._pivotFamily?.id || '').trim();
    if (!familyId) continue;
    const key = `${job.id}::${familyId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    merged.push(job);
    if (merged.length >= maxPool) break;
  }

  return merged;
}

function buildOpportunitySignals(profile) {
  const keywords = Array.isArray(profile?.keywords) ? profile.keywords : [];
  const skills = Array.isArray(profile?.skills) ? profile.skills : [];
  const roles = Array.isArray(profile?.roles) ? profile.roles : [];
  const inferredRoles = Array.isArray(profile?.inferredRoles) ? profile.inferredRoles : [];
  const summary = typeof profile?.summary === 'string' ? profile.summary : '';
  const cvText = typeof profile?.cvText === 'string'
    ? profile.cvText.slice(0, 4000)
    : '';

  return uniquePreservingOrder([
    ...keywords,
    ...skills,
    ...roles,
    ...inferredRoles,
    summary,
    cvText
  ]);
}

module.exports = { buildPivotJobPool, buildOpportunitySignals };
