const { resolveOccupationIds } = require('./occupationResolver');
const { buildCandidateOpportunityProfile } = require('../opportunity/candidateOpportunityProfile');
const { buildMatchJobPool } = require('./coreJobPoolBuilder');
const { buildPivotJobPool, buildOpportunitySignals } = require('./pivotJobPoolBuilder');
const { uniquePreservingOrder } = require('./jobPoolUtils');

async function buildMatchJobPools(profile, limit) {
  const explicitRoles = Array.isArray(profile?.roles) ? profile.roles : [];
  const inferredRoles = Array.isArray(profile?.inferredRoles) ? profile.inferredRoles : [];

  let coreOccupationIds = Array.isArray(profile?.occupationIds)
    ? uniquePreservingOrder(profile.occupationIds.map(String))
    : [];

  if (!coreOccupationIds.length) {
    const resolved = await resolveOccupationIds(explicitRoles, inferredRoles);
    coreOccupationIds = resolved.occupationIds || [];
  }

  const opportunityProfile = await buildCandidateOpportunityProfile({
    explicitRoles,
    inferredRoles,
    summary: profile?.summary,
    profileSignals: buildOpportunitySignals(profile),
    coreOccupationIds
  });

  const corePool = await buildMatchJobPool(
    {
      ...profile,
      occupationIds: coreOccupationIds
    },
    limit
  );

  const pivotPool = await buildPivotJobPool({
    profile,
    limit,
    opportunityProfile,
    coreOccupationIds
  });

  const cappedCorePool = corePool.slice(0, Math.min(corePool.length, Math.max(limit * 6, 120)));
  const cappedPivotPool = pivotPool.slice(0, Math.min(pivotPool.length, Math.max(limit * 4, 100)));

  return {
    corePool: tagPool(cappedCorePool, 'core'),
    pivotPool: tagPool(cappedPivotPool, 'pivot'),
    opportunityProfile
  };
}

function tagPool(pool, matchType) {
  return (Array.isArray(pool) ? pool : []).map((job) => ({
    ...job,
    _matchType: matchType
  }));
}

module.exports = { buildMatchJobPool, buildMatchJobPools };
