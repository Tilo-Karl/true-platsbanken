const { postOpenAI } = require('../readers/openai');
const { buildRoleExpansionPayload, parseRoleExpansionResponse } = require('../domain/profile/roleExpansion');

async function expandProfileRoles(profile) {
  if (!profile || typeof profile !== 'object') {
    throw new Error('profile is required');
  }

  const payload = buildRoleExpansionPayload(profile);
  const response = await postOpenAI('/v1/chat/completions', payload);
  return parseRoleExpansionResponse(response);
}

module.exports = { expandProfileRoles };
