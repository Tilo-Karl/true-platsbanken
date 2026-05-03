const { listJobTechJobs } = require('../jobs/jobTechJobs');
const { filterJobsByMunicipality } = require('../jobs/filterJobs');
const { resolveOccupationIds, expandOccupationNeighbors } = require('./occupationResolver');
const { buildCandidateOpportunityProfile } = require('../opportunity/candidateOpportunityProfile');

const SENIORITY_TOKENS = new Set([
  'senior',
  'junior',
  'lead',
  'principal',
  'staff',
  'manager',
  'chef',
  'ansvarig'
]);

const MAX_QUERIES = 8;
const MIN_QUERY_LENGTH = 3;
const MAX_POOL = 200;
const MIN_POOL = 40;
const MAX_PER_OCCUPATION = 40;
const MAX_PIVOT_POOL = 180;
const MAX_PIVOT_PER_OCCUPATION = 24;
const MAX_PIVOT_QUERIES = 12;

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

    pool = mergePools(pool, familyPool, maxPool);
    logPoolSize(`pivot_family_${familyId}`, familyPool);
    if (pool.length >= maxPool) break;
  }

  logPoolSize('pivot_final', pool);

  return pool;
}

function tagPool(pool, matchType) {
  return (Array.isArray(pool) ? pool : []).map((job) => ({
    ...job,
    _matchType: matchType
  }));
}

function computePivotPerOccupationLimit(occupationCount, limit) {
  const targetPool = Math.min(Math.max(limit * 5, 80), MAX_PIVOT_POOL);
  if (!occupationCount) return Math.min(targetPool, MAX_PIVOT_PER_OCCUPATION);
  const perOccupation = Math.ceil(targetPool / occupationCount);
  return Math.min(Math.max(perOccupation, 12), MAX_PIVOT_PER_OCCUPATION);
}

function computePivotPerQueryLimit(queryCount, limit) {
  const targetPool = Math.min(Math.max(limit * 5, 80), MAX_PIVOT_POOL);
  if (!queryCount) return Math.min(targetPool, 40);
  const perQuery = Math.ceil(targetPool / queryCount);
  return Math.min(Math.max(perQuery, 16), 40);
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

function computePerQueryLimit(queryCount, limit) {
  const targetPool = Math.min(Math.max(limit * 6, MIN_POOL), MAX_POOL);
  if (!queryCount) return Math.min(targetPool, 60);
  const perQuery = Math.ceil(targetPool / queryCount);
  return Math.min(Math.max(perQuery, 25), 60);
}

function computePerOccupationLimit(occupationCount, limit) {
  const targetPool = Math.min(Math.max(limit * 6, MIN_POOL), MAX_POOL);
  if (!occupationCount) return Math.min(targetPool, MAX_PER_OCCUPATION);
  const perOccupation = Math.ceil(targetPool / occupationCount);
  return Math.min(Math.max(perOccupation, 20), MAX_PER_OCCUPATION);
}

function buildRoleQueries(roles) {
  if (!Array.isArray(roles)) return [];
  const values = [];
  for (const role of roles) {
    if (!role) continue;
    const parts = String(role)
      .split(/[,/]/)
      .map(part => part.trim())
      .filter(Boolean);
    values.push(...parts);
  }
  return uniquePreservingOrder(values)
    .map(normalizeQuery)
    .filter(query => query.length >= MIN_QUERY_LENGTH);
}

function broadenQueries(queries) {
  const broadened = queries
    .map(query => stripSeniority(query))
    .map(normalizeQuery)
    .filter(query => query.length >= MIN_QUERY_LENGTH);
  return uniquePreservingOrder(broadened);
}

function stripSeniority(query) {
  const tokens = String(query)
    .split(/\s+/)
    .map(token => token.trim())
    .filter(Boolean);
  const filtered = tokens.filter(token => !SENIORITY_TOKENS.has(token.toLowerCase()));
  return filtered.join(' ');
}

function normalizeQuery(value) {
  return String(value).trim();
}

async function fetchJobsForOccupationIds(occupationIds, options) {
  if (!occupationIds.length) {
    return { pool: [], perOccupationCounts: {} };
  }

  const tasks = occupationIds.map(id =>
    listJobTechJobs({
      occupationIds: [id],
      limit: options.perOccupationLimit
    })
  );

  const responses = await Promise.all(tasks);
  const seen = new Set();
  const results = [];
  const perOccupationCounts = {};

  for (let index = 0; index < responses.length; index += 1) {
    const response = responses[index];
    const occupationId = occupationIds[index];
    const jobs = options.municipality
      ? filterJobsByMunicipality(response.jobs, options.municipality)
      : response.jobs;

    perOccupationCounts[occupationId] = jobs.length;

    for (const job of jobs) {
      if (!job || !job.id) continue;
      if (seen.has(job.id)) continue;
      seen.add(job.id);
      const mappedJob = typeof options.decorateJob === 'function'
        ? options.decorateJob(job, occupationId)
        : job;
      if (!mappedJob || !mappedJob.id) continue;
      results.push(mappedJob);
      if (results.length >= options.maxPool) {
        return { pool: results, perOccupationCounts };
      }
    }
  }

  return { pool: results, perOccupationCounts };
}

async function fetchJobsForQueries(queries, options) {
  if (!queries.length) {
    return [];
  }

  const tasks = queries.map(query =>
    listJobTechJobs({
      q: query,
      limit: options.perQueryLimit
    })
  );

  const responses = await Promise.all(tasks);
  const seen = new Set();
  const results = [];

  for (const response of responses) {
    const jobs = options.municipality
      ? filterJobsByMunicipality(response.jobs, options.municipality)
      : response.jobs;

    for (const job of jobs) {
      if (!job || !job.id) continue;
      if (seen.has(job.id)) continue;
      seen.add(job.id);
      const mappedJob = typeof options.decorateJob === 'function'
        ? options.decorateJob(job, response)
        : job;
      if (!mappedJob || !mappedJob.id) continue;
      results.push(mappedJob);
      if (results.length >= options.maxPool) {
        return results;
      }
    }
  }

  return results;
}

function uniquePreservingOrder(values) {
  const seen = new Set();
  const result = [];
  for (const value of values) {
    const key = String(value).trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    result.push(String(value).trim());
  }
  return result;
}

function logPoolSummary(stage, queries, context) {
  console.log('Match pool summary:', {
    stage,
    queryCount: queries.length,
    sampleQueries: queries.slice(0, 5),
    ...context
  });
}

function logPoolSize(stage, pool) {
  console.log('Match pool size:', {
    stage,
    count: pool.length
  });
}

function logRoleResolution(roles, inferredRoles, resolved) {
  console.log('Match role resolution:', {
    roles,
    inferredRoles,
    occupationIds: resolved.occupationIds || [],
    unmappedRoles: resolved.unmappedRoles || []
  });
}

function logOccupationExpansion(seedIds, expandedIds, neighbors) {
  console.log('Match occupation expansion:', {
    seedCount: seedIds.length,
    expandedCount: expandedIds.length,
    sampleExpanded: expandedIds.slice(0, 5),
    neighbors
  });
}

function logOccupationCounts(stage, counts) {
  console.log('Match occupation counts:', {
    stage,
    counts
  });
}

function mergePools(primary, secondary, maxPool) {
  const seen = new Set(primary.map(job => job.id));
  const merged = [...primary];
  for (const job of secondary) {
    if (!job || !job.id) continue;
    if (seen.has(job.id)) continue;
    seen.add(job.id);
    merged.push(job);
    if (merged.length >= maxPool) break;
  }
  return merged;
}

module.exports = { buildMatchJobPool, buildMatchJobPools };
