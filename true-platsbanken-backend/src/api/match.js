const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { buildProfileSignalsFromProfile } = require('../domain/profile/profileSignalInput');
const { buildEmbeddingInputs, extractEmbeddings } = require('../domain/matching/embeddingText');
const { rankSemanticMatches } = require('../domain/matching/semanticMatch');
const { buildMatchJobPools } = require('../domain/matching/jobPool');
const { adjustPivotRanking } = require('../domain/matching/pivotRankingPolicy');
const { selectPivotMatches } = require('../domain/matching/pivotFinalSelection');
const { postOpenAI } = require('../readers/openai');

async function getSemanticMatches(db, request) {
  const { profile, limit, profileEmbedding } = normalizeMatchRequest(request);
  if (!profile) {
    throw new Error('profile is required');
  }

  const profileSignals = buildProfileSignalsFromProfile(profile);

  const { corePool, pivotPool, opportunityProfile } = await buildMatchJobPools(profile, limit);
  const jobs = [...corePool, ...pivotPool];

  if (jobs.length === 0) {
    return {
      matches: [],
      coreMatches: [],
      pivotMatches: [],
      count: 0,
      coreCount: 0,
      pivotCount: 0,
      opportunityProfile
    };
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

  const { coreJobs, coreEmbeddings, pivotJobs, pivotEmbeddings } = splitJobsAndEmbeddingsByType(
    jobs,
    jobEmbeddings
  );

  const coreRanked = rankSemanticMatches(
    coreJobs,
    resolvedProfileEmbedding,
    coreEmbeddings,
    profileSignals,
    coreJobs.length
  );
  const pivotRanked = rankSemanticMatches(
    pivotJobs,
    resolvedProfileEmbedding,
    pivotEmbeddings,
    profileSignals,
    pivotJobs.length
  );

  const adjustedPivotMatches = adjustPivotRanking(pivotRanked, opportunityProfile);
  const coreMatches = coreRanked.slice(0, limit);
  const pivotMatches = selectPivotMatches(adjustedPivotMatches, limit);
  const matches = [...coreMatches, ...pivotMatches];
  const cleanedCoreMatches = stripInternalRankingFields(coreMatches);
  const cleanedPivotMatches = stripInternalRankingFields(pivotMatches);
  const cleanedMatches = stripInternalRankingFields(matches);

  console.log('Match debug: matches', cleanedMatches.length);
  return {
    matches: cleanedMatches,
    coreMatches: cleanedCoreMatches,
    pivotMatches: cleanedPivotMatches,
    count: cleanedMatches.length,
    coreCount: cleanedCoreMatches.length,
    pivotCount: cleanedPivotMatches.length,
    opportunityProfile
  };
}

function stripInternalRankingFields(matches) {
  return (Array.isArray(matches) ? matches : []).map(({ _rankScore, ...rest }) => rest);
}

function splitJobsAndEmbeddingsByType(jobs, jobEmbeddings) {
  const coreJobs = [];
  const coreEmbeddings = [];
  const pivotJobs = [];
  const pivotEmbeddings = [];

  for (let index = 0; index < jobs.length; index += 1) {
    const job = jobs[index];
    const embedding = Array.isArray(jobEmbeddings) ? jobEmbeddings[index] : null;
    if (job?._matchType === 'pivot') {
      pivotJobs.push(job);
      pivotEmbeddings.push(embedding);
      continue;
    }
    coreJobs.push(job);
    coreEmbeddings.push(embedding);
  }

  return { coreJobs, coreEmbeddings, pivotJobs, pivotEmbeddings };
}

module.exports = { getSemanticMatches };
