const { resolveOccupationIds, expandOccupationNeighbors } = require('./occupationResolver');
const { fetchJobsForOccupationIds, fetchJobsForQueries } = require('./jobPoolFetchers');
const {
  buildRoleQueries,
  broadenQueries,
  computePerQueryLimit,
  computePerOccupationLimit,
  uniquePreservingOrder,
  mergePools,
  logPoolSummary,
  logPoolSize,
  logRoleResolution,
  logOccupationExpansion,
  logOccupationCounts
} = require('./jobPoolUtils');
const { MAX_QUERIES, MAX_POOL, MIN_POOL } = require('./jobPoolConstants');

async function buildMatchJobPool(profile, limit) {
  const explicitRoles = Array.isArray(profile?.roles) ? profile.roles : [];
  const inferredRoles = Array.isArray(profile?.inferredRoles) ? profile.inferredRoles : [];

  const municipality = profile?.municipality ? String(profile.municipality).trim() : '';
  const hasMunicipality = Boolean(municipality);

  let occupationIds = Array.isArray(profile?.occupationIds)
    ? profile.occupationIds.map(String)
    : [];
  let unresolvedRoles = [];

  if (!occupationIds.length) {
    const resolved = await resolveOccupationIds(explicitRoles, inferredRoles);
    occupationIds = resolved.occupationIds;
    unresolvedRoles = resolved.unmappedRoles;
    logRoleResolution(explicitRoles, inferredRoles, resolved);
  } else {
    logRoleResolution(explicitRoles, inferredRoles, {
      occupationIds,
      unmappedRoles: []
    });
  }

  let pool = [];

  if (occupationIds.length) {
    const { expandedOccupationIds, neighbors } = await expandOccupationNeighbors(occupationIds);
    logOccupationExpansion(occupationIds, expandedOccupationIds, neighbors);

    const options = {
      perOccupationLimit: computePerOccupationLimit(expandedOccupationIds.length, limit),
      maxPool: MAX_POOL,
      municipality: hasMunicipality ? municipality : null
    };

    let result = await fetchJobsForOccupationIds(expandedOccupationIds, options);
    pool = result.pool;
    logOccupationCounts('occupation_ids', result.perOccupationCounts);
    logPoolSize('occupation_ids', pool);

    if (pool.length < MIN_POOL && hasMunicipality) {
      result = await fetchJobsForOccupationIds(expandedOccupationIds, {
        ...options,
        municipality: null
      });
      pool = result.pool;
      logOccupationCounts('drop_municipality', result.perOccupationCounts);
      logPoolSize('drop_municipality', pool);
    }
  }

  if (!occupationIds.length) {
    const explicitQueries = buildRoleQueries(explicitRoles);
    const inferredQueries = buildRoleQueries(inferredRoles);
    const baseQueries = uniquePreservingOrder([...explicitQueries, ...inferredQueries])
      .slice(0, MAX_QUERIES);

    if (!baseQueries.length) {
      return [];
    }

    const baseOptions = {
      perQueryLimit: computePerQueryLimit(baseQueries.length, limit),
      maxPool: MAX_POOL
    };

    logPoolSummary('base', baseQueries, {
      municipality: hasMunicipality ? municipality : null,
      perQueryLimit: baseOptions.perQueryLimit
    });

    pool = await fetchJobsForQueries(baseQueries, {
      ...baseOptions,
      municipality: hasMunicipality ? municipality : null
    });
    logPoolSize('base', pool);

    if (pool.length < MIN_POOL && hasMunicipality) {
      pool = await fetchJobsForQueries(baseQueries, {
        ...baseOptions,
        municipality: null
      });
      logPoolSize('drop_municipality', pool);
    }

    if (pool.length < MIN_POOL) {
      const broadened = broadenQueries(baseQueries);
      if (broadened.length) {
        logPoolSummary('broadened', broadened, {
          municipality: null,
          perQueryLimit: baseOptions.perQueryLimit
        });
        pool = await fetchJobsForQueries(broadened, {
          ...baseOptions,
          municipality: null
        });
        logPoolSize('broadened', pool);
      }
    }

    if (pool.length < MIN_POOL && explicitQueries.length) {
      const explicitOnly = uniquePreservingOrder(explicitQueries).slice(0, MAX_QUERIES);
      logPoolSummary('explicit_only', explicitOnly, {
        municipality: null,
        perQueryLimit: baseOptions.perQueryLimit
      });
      pool = await fetchJobsForQueries(explicitOnly, {
        ...baseOptions,
        municipality: null
      });
      logPoolSize('explicit_only', pool);
    }
  } else if (unresolvedRoles.length && pool.length < MIN_POOL) {
    const fallbackQueries = buildRoleQueries(unresolvedRoles).slice(0, MAX_QUERIES);
    if (fallbackQueries.length) {
      const fallbackOptions = {
        perQueryLimit: computePerQueryLimit(fallbackQueries.length, limit),
        maxPool: MAX_POOL - pool.length
      };
      logPoolSummary('fallback_unmapped', fallbackQueries, {
        municipality: hasMunicipality ? municipality : null,
        perQueryLimit: fallbackOptions.perQueryLimit
      });
      const fallbackPool = await fetchJobsForQueries(fallbackQueries, {
        ...fallbackOptions,
        municipality: hasMunicipality ? municipality : null
      });
      pool = mergePools(pool, fallbackPool, MAX_POOL);
      logPoolSize('fallback_unmapped', pool);
    }
  }

  logPoolSize('final', pool);
  return pool;
}

module.exports = { buildMatchJobPool };
