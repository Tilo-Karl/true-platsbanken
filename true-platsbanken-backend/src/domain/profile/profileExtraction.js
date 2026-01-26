const { buildProfileExtractionMessages } = require('../ai/openaiPrompts');

function buildProfileExtractionPayload(text, model = 'gpt-4o-mini') {
  return {
    model,
    temperature: 0,
    response_format: { type: 'json_object' },
    messages: buildProfileExtractionMessages(text)
  };
}

function parseProfileExtractionResponse(payload) {
  const content = payload?.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('OpenAI chat response is empty');
  }

  return normalizeExtraction(JSON.parse(content));
}

function normalizeExtraction(value) {
  const keywords = Array.isArray(value?.keywords) ? value.keywords.map(String) : [];
  const roles = Array.isArray(value?.roles) ? value.roles.map(String) : [];
  const locations = Array.isArray(value?.locations) ? value.locations.map(String) : [];
  const seniority = typeof value?.seniority === 'string' ? value.seniority : null;
  const summary = typeof value?.summary === 'string' ? value.summary : '';

  return { keywords, roles, seniority, locations, summary };
}

module.exports = { buildProfileExtractionPayload, parseProfileExtractionResponse };
