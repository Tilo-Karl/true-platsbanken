const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { matchQueryOptions } = require('../domain/matching/matchQueryOptions');
const { buildProfileSignalsFromProfile } = require('../domain/profile/profileSignalInput');
const { buildEmbeddingInputs, extractEmbeddings } = require('../domain/matching/embeddingText');
const { rankSemanticMatches } = require('../domain/matching/semanticMatch');
const { listJobTechJobs } = require('../domain/jobs/jobTechJobs');
const { filterJobsByMunicipality } = require('../domain/jobs/filterJobs');
const { postOpenAI } = require('../readers/openai');

async function getSemanticMatches(db, request) {
  const { profile, limit } = normalizeMatchRequest(request);
  if (!profile) {
    throw new Error('profile is required');
  }

  const profileSignals = buildProfileSignalsFromProfile(profile);

  const options = matchQueryOptions(profile, limit);
  const jobResponse = await listJobTechJobs({ limit: options.limit });
  const jobs = filterJobsByMunicipality(jobResponse.jobs, options.municipality);

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
