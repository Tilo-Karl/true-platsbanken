const { requireFirestoreDb } = require('../invariants/requireFirestoreDb');
const { requireProfileId } = require('../invariants/requireProfileId');
const { requireProfileExists } = require('../invariants/requireProfileExists');
const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { matchQueryOptions } = require('../domain/matching/matchQueryOptions');
const { rankMatches } = require('../domain/matching/rankMatches');
const { buildProfileSignalsFromProfile } = require('../domain/profile/profileSignalInput');
const { buildEmbeddingInputs, extractEmbeddings } = require('../domain/matching/embeddingText');
const { listJobTechJobs } = require('../domain/jobs/jobTechJobs');
const { filterJobsByMunicipality } = require('../domain/jobs/filterJobs');
const { getProfileById } = require('../readers/profiles');
const { postOpenAI } = require('../readers/openai');

async function getMatches(db, request) {
  requireFirestoreDb(db);

  const { profileId, limit } = normalizeMatchRequest(request);
  requireProfileId(profileId);

  const profile = await getProfileById(db, profileId);
  requireProfileExists(profile);

  const profileSignals = buildProfileSignalsFromProfile(profile);

  const options = matchQueryOptions(profile, limit);
  const jobResponse = await listJobTechJobs({ limit: options.limit });
  const jobs = filterJobsByMunicipality(jobResponse.jobs, options.municipality);

  let profileEmbedding = null;
  let jobEmbeddings = [];

  if (jobs.length > 0) {
    const { inputs } = buildEmbeddingInputs(profileSignals, jobs);
    const payload = await postOpenAI('/v1/embeddings', {
      model: 'text-embedding-3-large',
      input: inputs
    });
    const extracted = extractEmbeddings(payload);
    profileEmbedding = extracted.profileEmbedding;
    jobEmbeddings = extracted.jobEmbeddings;
  }

  const matches = rankMatches(
    profile,
    profileSignals,
    jobs,
    limit,
    profileEmbedding,
    jobEmbeddings
  );

  return { matches, count: matches.length };
}

module.exports = { getMatches };
