const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { buildProfileSignalsFromProfile } = require('../domain/profile/profileSignalInput');
const { buildEmbeddingInputs, extractEmbeddings } = require('../domain/matching/embeddingText');
const { rankSemanticMatches } = require('../domain/matching/semanticMatch');
const { buildMatchJobPool } = require('../domain/matching/jobPool');
const { postOpenAI } = require('../readers/openai');

async function getSemanticMatches(db, request) {
  const { profile, limit, profileEmbedding } = normalizeMatchRequest(request);
  if (!profile) {
    throw new Error('profile is required');
  }

  const profileSignals = buildProfileSignalsFromProfile(profile);

  const jobs = await buildMatchJobPool(profile, limit);

  if (jobs.length === 0) {
    return { matches: [], count: 0 };
  }

  const { profileText, jobTexts, inputs } = buildEmbeddingInputs(profileSignals, jobs);
  console.log('Match debug: profileTextLength', profileText.length, 'jobTextCount', jobTexts.length);
  if (!profileText.trim()) {
    throw new Error('profile text is required for embeddings');
  }

  let resolvedProfileEmbedding = profileEmbedding;
  let jobEmbeddings = [];

  if (Array.isArray(profileEmbedding) && profileEmbedding.length > 0) {
    console.log('Match debug: using cached profile embedding', profileEmbedding.length);
    const payload = await postOpenAI('/v1/embeddings', {
      model: 'text-embedding-3-small',
      input: jobTexts
    });
    jobEmbeddings = Array.isArray(payload?.data)
      ? payload.data.map(item => item.embedding)
      : [];
  } else {
    console.log('Match debug: embedding profile + jobs');
    const payload = await postOpenAI('/v1/embeddings', {
      model: 'text-embedding-3-small',
      input: inputs
    });
    const extracted = extractEmbeddings(payload);
    resolvedProfileEmbedding = extracted.profileEmbedding;
    jobEmbeddings = extracted.jobEmbeddings;
  }

  console.log('Match debug: embeddings', {
    profileEmbeddingLength: Array.isArray(resolvedProfileEmbedding) ? resolvedProfileEmbedding.length : 0,
    jobEmbeddingsCount: Array.isArray(jobEmbeddings) ? jobEmbeddings.length : 0
  });

  const matches = rankSemanticMatches(jobs, resolvedProfileEmbedding, jobEmbeddings, profileSignals, limit);
  console.log('Match debug: matches', matches.length);
  return { matches, count: matches.length };
}

module.exports = { getSemanticMatches };
