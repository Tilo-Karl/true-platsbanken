const { requireFirestoreDb } = require('../invariants/requireFirestoreDb');
const { requireProfileId } = require('../invariants/requireProfileId');
const { requireProfileExists } = require('../invariants/requireProfileExists');
const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { matchQueryOptions } = require('../domain/matching/matchQueryOptions');
const { buildProfileSignalsFromProfile } = require('../domain/profile/profileSignalInput');
const { buildEmbeddingInputs, extractEmbeddings } = require('../domain/matching/embeddingText');
const { rankSemanticMatches } = require('../domain/matching/semanticMatch');
const { getProfileById } = require('../readers/profiles');
const { listJobsForMatching } = require('../readers/jobs');
const { postOpenAI } = require('../readers/openai');

async function getSemanticMatches(db, request) {
  requireFirestoreDb(db);

  const { profileId, limit } = normalizeMatchRequest(request);
  requireProfileId(profileId);

  const profile = await getProfileById(db, profileId);
  requireProfileExists(profile);

  const profileSignals = buildProfileSignalsFromProfile(profile);

  const options = matchQueryOptions(profile, limit);
  const jobs = await listJobsForMatching(db, options);

  if (jobs.length === 0) {
    return { matches: [], count: 0 };
  }

  const { inputs } = buildEmbeddingInputs(profileSignals, jobs);
  const payload = await postOpenAI('/v1/embeddings', {
    model: 'text-embedding-3-small',
    input: inputs
  });
  const extracted = extractEmbeddings(payload);
  const profileEmbedding = extracted.profileEmbedding;
  const jobEmbeddings = extracted.jobEmbeddings;

  const matches = rankSemanticMatches(jobs, profileEmbedding, jobEmbeddings, profileSignals, limit);
  return { matches, count: matches.length };
}

module.exports = { getSemanticMatches };
