const { postOpenAI } = require('../readers/openai');
const { buildProfileExtractionPayload, parseProfileExtractionResponse } = require('../domain/profile/profileExtraction');

async function extractProfile(text) {
  if (typeof text !== 'string' || text.trim().length === 0) {
    throw new Error('text is required');
  }

  const payload = buildProfileExtractionPayload(text);
  const response = await postOpenAI('/v1/chat/completions', payload);
  return parseProfileExtractionResponse(response);
}

module.exports = { extractProfile };
