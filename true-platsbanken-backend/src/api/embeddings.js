const { postOpenAI } = require('../readers/openai');
const { buildProfileSignalsFromProfile } = require('../domain/profile/profileSignalInput');
const { buildProfileEmbeddingText } = require('../domain/matching/embeddingText');

async function createEmbeddings(request) {
  const profile = request?.profile;
  if (!profile || typeof profile !== 'object') {
    throw new Error('profile is required');
  }

  const profileSignals = buildProfileSignalsFromProfile(profile);
  const profileText = buildProfileEmbeddingText(profileSignals);
  if (!profileText.trim()) {
    throw new Error('profile text is required');
  }

  const payload = await postOpenAI('/v1/embeddings', {
    model: 'text-embedding-3-small',
    input: [profileText]
  });

  const embedding = Array.isArray(payload?.data) ? payload.data[0]?.embedding : null;
  if (!embedding) {
    throw new Error('embedding is missing');
  }

  return { embedding };
}

module.exports = { createEmbeddings };
