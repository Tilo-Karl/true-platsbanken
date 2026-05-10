const { postOpenAI } = require('../readers/openai');
const { buildRoleExpansionPayload, parseRoleExpansionResponse } = require('../domain/profile/roleExpansion');
const { resolveOccupationIds } = require('../domain/matching/occupationResolver');
const { applyInferredRoleGuardrails, normalizeRoleArray } = require('../domain/profile/inferredRoleGuardrails');
const { uniqueCaseInsensitiveStrings } = require('../domain/shared/uniqueCaseInsensitiveStrings');
const { resolveEducationPaths } = require('../domain/education/educationPathResolver');
const { buildCandidateOpportunityProfile } = require('../domain/opportunity/candidateOpportunityProfile');

async function expandProfileRoles(profile) {
  if (!profile || typeof profile !== 'object') {
    throw new Error('profile is required');
  }

  const explicitRoles = normalizeRoleArray(profile.roles);

  const payload = buildRoleExpansionPayload(profile);
  const response = await postOpenAI('/v1/chat/completions', payload);
  const expansion = parseRoleExpansionResponse(response);
  const inferredNoCanonicalDuplicates = await applyInferredRoleGuardrails(
    explicitRoles,
    expansion.inferredRoleDetails
  );

  const inferredRoles = inferredNoCanonicalDuplicates.map(item => item.role);
  const rationale = buildRationale(expansion.rationale, inferredNoCanonicalDuplicates);
  const [explicitResolved, inferredResolved] = await Promise.all([
    resolveOccupationIds(explicitRoles, []),
    resolveOccupationIds([], inferredRoles)
  ]);

  const occupationIds = uniquePreservingOrder([
    ...(explicitResolved.occupationIds || []),
    ...(inferredResolved.occupationIds || [])
  ]);

  let opportunityProfile = null;
  try {
    opportunityProfile = await buildCandidateOpportunityProfile({
      explicitRoles,
      inferredRoles,
      summary: profile.summary,
      profileSignals: buildPivotSignals(profile),
      coreOccupationIds: occupationIds
    });
  } catch (error) {
    console.log('Candidate opportunity profile build failed:', error.message);
  }

  let educationPath = { strengthen: [], pivot: [] };
  try {
    educationPath = await resolveEducationPaths({
      explicitOccupationIds: explicitResolved.occupationIds || [],
      inferredOccupationIds: inferredResolved.occupationIds || [],
      explicitRoles,
      inferredRoles,
      inferredRoleDetails: inferredNoCanonicalDuplicates,
      profileSignals: buildEducationSignals(profile, inferredNoCanonicalDuplicates),
      pivotSignals: buildPivotSignals(profile)
    });
  } catch (error) {
    console.log('Education path resolver failed:', error.message);
  }

  return {
    ...expansion,
    inferredRoles,
    inferredRoleDetails: inferredNoCanonicalDuplicates,
    rationale,
    occupationIds,
    opportunityProfile,
    educationPath
  };
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

function buildEducationSignals(profile, inferredRoleDetails) {
  const keywords = Array.isArray(profile?.keywords) ? profile.keywords : [];
  const roles = Array.isArray(profile?.roles) ? profile.roles : [];
  const summary = typeof profile?.summary === 'string' ? profile.summary : '';
  const detailSignals = inferredRoleDetails.flatMap((item) => {
    if (!item || typeof item !== 'object') return [];
    if (Array.isArray(item.sourceSignals)) return item.sourceSignals;
    if (typeof item.reason === 'string') return [item.reason];
    return [];
  });

  return uniquePreservingOrder([
    ...keywords,
    ...roles,
    ...detailSignals,
    summary
  ]).filter(Boolean);
}

function buildPivotSignals(profile) {
  const keywords = Array.isArray(profile?.keywords) ? profile.keywords : [];
  const roles = Array.isArray(profile?.roles) ? profile.roles : [];
  const summary = typeof profile?.summary === 'string' ? profile.summary : '';

  return uniquePreservingOrder([
    ...keywords,
    ...roles,
    summary
  ]).filter(Boolean);
}

function uniquePreservingOrder(values) {
  return uniqueCaseInsensitiveStrings(values);
}

module.exports = { expandProfileRoles };
