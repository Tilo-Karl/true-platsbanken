const { postOpenAI } = require('../readers/openai');
const { buildRoleExpansionPayload, parseRoleExpansionResponse } = require('../domain/profile/roleExpansion');
const { resolveOccupationIds } = require('../domain/matching/occupationResolver');

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

async function expandProfileRoles(profile) {
  if (!profile || typeof profile !== 'object') {
    throw new Error('profile is required');
  }

  const explicitRoles = normalizeRoleArray(profile.roles);

  const payload = buildRoleExpansionPayload(profile);
  const response = await postOpenAI('/v1/chat/completions', payload);
  const expansion = parseRoleExpansionResponse(response);
  const inferredRoleDetails = filterLexicalDuplicates(
    Array.isArray(expansion.inferredRoleDetails) ? expansion.inferredRoleDetails : [],
    explicitRoles
  );

  const inferredNoCanonicalDuplicates = await filterCanonicalDuplicates(
    explicitRoles,
    inferredRoleDetails
  );

  const inferredRoles = inferredNoCanonicalDuplicates.map(item => item.role);
  const rationale = buildRationale(expansion.rationale, inferredNoCanonicalDuplicates);
  const resolved = await resolveOccupationIds(explicitRoles, inferredRoles);

  return {
    ...expansion,
    inferredRoles,
    inferredRoleDetails: inferredNoCanonicalDuplicates,
    rationale,
    occupationIds: resolved.occupationIds
  };
}

async function filterCanonicalDuplicates(explicitRoles, inferredRoleDetails) {
  if (!explicitRoles.length || !inferredRoleDetails.length) {
    return inferredRoleDetails;
  }

  const explicitResolved = await resolveOccupationIds(explicitRoles, []);
  const inferredRoles = inferredRoleDetails.map(item => item.role);
  const inferredResolved = await resolveOccupationIds([], inferredRoles);

  const explicitOccupationIds = new Set(explicitResolved.occupationIds || []);
  return inferredRoleDetails.filter(item => {
    const resolved = inferredResolved.resolved?.[item.role];
    const inferredOccupationId = resolved?.id || null;
    return !inferredOccupationId || !explicitOccupationIds.has(inferredOccupationId);
  });
}

function filterLexicalDuplicates(inferredRoleDetails, explicitRoles) {
  if (!explicitRoles.length) return inferredRoleDetails;
  return inferredRoleDetails.filter(item => !isLexicalDuplicate(item.role, explicitRoles));
}

function isLexicalDuplicate(role, explicitRoles) {
  const normalizedRole = normalize(role);
  const roleTokens = tokenizeWithoutSeniority(role);
  if (!normalizedRole || !roleTokens.length) return true;

  for (const explicitRole of explicitRoles) {
    const normalizedExplicit = normalize(explicitRole);
    if (!normalizedExplicit) continue;

    if (normalizedRole === normalizedExplicit) {
      return true;
    }

    if (
      normalizedRole.includes(normalizedExplicit) ||
      normalizedExplicit.includes(normalizedRole)
    ) {
      return true;
    }

    const explicitTokens = tokenizeWithoutSeniority(explicitRole);
    if (!explicitTokens.length) continue;

    const intersectionSize = intersection(roleTokens, explicitTokens).size;
    const unionSize = new Set([...roleTokens, ...explicitTokens]).size;
    const jaccard = unionSize ? intersectionSize / unionSize : 0;

    if (intersectionSize >= 2 && jaccard >= 0.72) {
      return true;
    }
  }

  return false;
}

function tokenizeWithoutSeniority(value) {
  return tokenize(value).filter(token => !SENIORITY_TOKENS.has(token));
}

function tokenize(value) {
  return normalize(value)
    .split(' ')
    .map(token => token.trim())
    .filter(Boolean);
}

function normalize(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function intersection(a, b) {
  const result = new Set();
  for (const value of a) {
    if (b.includes(value)) {
      result.add(value);
    }
  }
  return result;
}

function normalizeRoleArray(roles) {
  if (!Array.isArray(roles)) return [];
  const seen = new Set();
  const result = [];
  for (const role of roles) {
    const value = String(role || '').trim();
    const key = value.toLowerCase();
    if (!value || seen.has(key)) continue;
    seen.add(key);
    result.push(value);
  }
  return result;
}

function buildRationale(baseRationale, inferredRoleDetails) {
  const rationale = typeof baseRationale === 'object' && baseRationale !== null
    ? { ...baseRationale }
    : {};
  for (const role of inferredRoleDetails) {
    rationale[role.role] = role.reason;
  }
  return rationale;
}

module.exports = { expandProfileRoles };
