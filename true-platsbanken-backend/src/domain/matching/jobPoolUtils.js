const {
  SENIORITY_TOKENS,
  MIN_QUERY_LENGTH,
  MIN_POOL,
  MAX_POOL,
  MAX_PER_OCCUPATION,
  MAX_PIVOT_POOL,
  MAX_PIVOT_PER_OCCUPATION
} = require('./jobPoolConstants');
const { uniqueCaseInsensitiveStrings } = require('../shared/uniqueCaseInsensitiveStrings');

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

function uniquePreservingOrder(values) {
  return uniqueCaseInsensitiveStrings(values);
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

module.exports = {
  buildRoleQueries,
  broadenQueries,
  computePerQueryLimit,
  computePerOccupationLimit,
  computePivotPerOccupationLimit,
  computePivotPerQueryLimit,
  uniquePreservingOrder,
  mergePools,
  logPoolSummary,
  logPoolSize,
  logRoleResolution,
  logOccupationExpansion,
  logOccupationCounts
};
