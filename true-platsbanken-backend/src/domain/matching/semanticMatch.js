const { buildMatchReasons } = require('./matchReasons');

function rankSemanticMatches(jobs, profileEmbedding, jobEmbeddings, profileSignals, limit) {
  if (!Array.isArray(jobs) || jobs.length === 0) {
    return [];
  }

  return jobs
    .map((job, index) => {
      const embedding = Array.isArray(jobEmbeddings) ? jobEmbeddings[index] : null;
      const score = cosineSimilarity(profileEmbedding, embedding);
      return {
        jobId: job.id,
        job,
        score,
        reasons: buildMatchReasons(profileSignals, job),
        matchType: job?._matchType || 'core'
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

function cosineSimilarity(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b)) {
    return 0;
  }

  let dot = 0;
  let normA = 0;
  let normB = 0;
  const length = Math.min(a.length, b.length);

  for (let i = 0; i < length; i += 1) {
    const x = a[i];
    const y = b[i];
    dot += x * y;
    normA += x * x;
    normB += y * y;
  }

  if (!normA || !normB) {
    return 0;
  }

  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

module.exports = { rankSemanticMatches };
