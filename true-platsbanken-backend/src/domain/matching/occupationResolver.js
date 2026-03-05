const { getTaxonomySnapshot } = require('../taxonomy/jobTechTaxonomy');

const MIN_CONFIDENCE = 0.65;
const MAX_ROLES = 12;
const MAX_NEIGHBORS = 2;
const MAX_EXPANDED = 30;

async function resolveOccupationIds(roles = [], inferredRoles = []) {
  const { occupationIndex } = await getTaxonomySnapshot();
  const allRoles = uniquePreservingOrder([...roles, ...inferredRoles]).slice(0, MAX_ROLES);

  const occupationIds = [];
  const unmappedRoles = [];
  const resolved = {};

  for (const role of allRoles) {
    const best = findBestMatch(role, occupationIndex);
    if (best && best.score >= MIN_CONFIDENCE) {
      occupationIds.push(best.id);
      resolved[role] = { id: best.id, label: best.label, score: best.score };
    } else {
      unmappedRoles.push(role);
    }
  }

  return {
    occupationIds: uniquePreservingOrder(occupationIds),
    unmappedRoles,
    resolved
  };
}

async function expandOccupationNeighbors(seedIds) {
  const { occupationToField, fieldToOccupations } = await getTaxonomySnapshot();
  const expanded = new Set(seedIds);
  const neighbors = {};

  for (const seedId of seedIds) {
    const fieldId = occupationToField.get(seedId);
    if (!fieldId) continue;
    const candidates = fieldToOccupations.get(fieldId) || [];
    const chosen = [];

    for (const occupation of candidates) {
      if (expanded.has(occupation.id)) continue;
      expanded.add(occupation.id);
      chosen.push(occupation.id);
      if (chosen.length >= MAX_NEIGHBORS) break;
      if (expanded.size >= MAX_EXPANDED) break;
    }

    if (chosen.length) {
      neighbors[seedId] = chosen;
    }

    if (expanded.size >= MAX_EXPANDED) break;
  }

  return {
    expandedOccupationIds: Array.from(expanded),
    neighbors
  };
}

function findBestMatch(role, occupationIndex) {
  const normalizedRole = normalize(role);
  if (!normalizedRole) return null;
  const roleTokens = tokenize(normalizedRole);

  let best = null;
  for (const occupation of occupationIndex) {
    const score = scoreCandidate(normalizedRole, roleTokens, occupation);
    if (!best || score > best.score) {
      best = { id: occupation.id, label: occupation.label, score };
    }
  }
  return best;
}

function scoreCandidate(role, roleTokens, occupation) {
  if (!occupation.normalized) return 0;
  if (role === occupation.normalized) return 1;
  if (occupation.normalized.startsWith(role)) return 0.92;
  if (role.startsWith(occupation.normalized)) return 0.9;
  if (occupation.normalized.includes(role)) return 0.88;
  if (role.includes(occupation.normalized)) return 0.85;

  const intersection = roleTokens.filter(token => occupation.tokens.includes(token));
  const union = new Set([...roleTokens, ...occupation.tokens]);
  const jaccard = union.size ? intersection.length / union.size : 0;

  const fullContain = roleTokens.length > 0 && roleTokens.every(token => occupation.tokens.includes(token))
    ? 0.8
    : 0;

  return Math.max(jaccard, fullContain);
}

function normalize(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(value) {
  return normalize(value)
    .split(' ')
    .filter(token => token.length > 1);
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

module.exports = { resolveOccupationIds, expandOccupationNeighbors };
