const { resolveOccupationIds } = require('../matching/occupationResolver');
const { uniqueCaseInsensitiveStrings } = require('../shared/uniqueCaseInsensitiveStrings');

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

async function applyInferredRoleGuardrails(explicitRoles, inferredRoleDetails) {
  const normalizedExplicitRoles = normalizeRoleArray(explicitRoles);
  const lexicalFiltered = filterLexicalDuplicates(
    Array.isArray(inferredRoleDetails) ? inferredRoleDetails : [],
    normalizedExplicitRoles
  );

  return filterCanonicalDuplicates(normalizedExplicitRoles, lexicalFiltered);
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
  return uniqueCaseInsensitiveStrings(roles);
}

module.exports = { applyInferredRoleGuardrails, normalizeRoleArray };
