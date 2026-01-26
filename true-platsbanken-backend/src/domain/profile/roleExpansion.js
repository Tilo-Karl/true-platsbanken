const { buildRoleExpansionMessages } = require('../ai/openaiPrompts');

function buildRoleExpansionPayload(profile, model = 'gpt-4o-mini') {
  return {
    model,
    temperature: 0,
    response_format: { type: 'json_object' },
    messages: buildRoleExpansionMessages(profile)
  };
}

function parseRoleExpansionResponse(payload) {
  const content = payload?.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('OpenAI chat response is empty');
  }

  return normalizeExpansion(JSON.parse(content));
}

function normalizeExpansion(value) {
  const inferredRoles = Array.isArray(value?.inferredRoles)
    ? value.inferredRoles.map(String)
    : [];
  const rationale = typeof value?.rationale === 'object' && value?.rationale !== null
    ? value.rationale
    : {};

  return { inferredRoles, rationale };
}

module.exports = { buildRoleExpansionPayload, parseRoleExpansionResponse };
