const { postOpenAI } = require('../readers/openai');
const { buildRoleExpansionPayload, parseRoleExpansionResponse } = require('../domain/profile/roleExpansion');
const { resolveOccupationIds } = require('../domain/matching/occupationResolver');

async function expandProfileRoles(profile) {
  if (!profile || typeof profile !== 'object') {
    throw new Error('profile is required');
  }

  const payload = buildRoleExpansionPayload(profile);
  const response = await postOpenAI('/v1/chat/completions', payload);
  const expansion = parseRoleExpansionResponse(response);
  const resolved = await resolveOccupationIds(profile.roles || [], expansion.inferredRoles || []);

  return {
    ...expansion,
    occupationIds: resolved.occupationIds
  };
}

module.exports = { expandProfileRoles };
