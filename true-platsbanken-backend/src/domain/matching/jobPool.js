const { listJobTechJobs } = require('../jobs/jobTechJobs');
const { filterJobsByMunicipality } = require('../jobs/filterJobs');

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
const MAX_POOL = 240;
const MIN_POOL = 40;

async function buildMatchJobPool(profile, limit) {
  const explicitQueries = buildRoleQueries(profile?.roles || []);
  const inferredQueries = buildRoleQueries(profile?.inferredRoles || []);
  const baseQueries = uniquePreservingOrder([...explicitQueries, ...inferredQueries])
    .slice(0, MAX_QUERIES);

  const municipality = profile?.municipality ? String(profile.municipality).trim() : '';
  const hasMunicipality = Boolean(municipality);

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

  let pool = await fetchJobsForQueries(baseQueries, {
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

  logPoolSize('final', pool);
  return pool;
}

function computePerQueryLimit(queryCount, limit) {
  const targetPool = Math.min(Math.max(limit * 6, MIN_POOL), MAX_POOL);
  if (!queryCount) return Math.min(targetPool, 60);
  const perQuery = Math.ceil(targetPool / queryCount);
  return Math.min(Math.max(perQuery, 25), 60);
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
      results.push(job);
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

module.exports = { buildMatchJobPool };
