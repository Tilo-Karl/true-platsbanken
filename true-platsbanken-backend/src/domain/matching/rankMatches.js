const { scoreProfile } = require('../../ai/match/score');

function rankMatches(profile, profileSignals, jobs, limit, profileEmbedding, jobEmbeddings) {
  return jobs
    .map((job, index) => {
      const baseScore = scoreProfile(profile, job, profileSignals);
      const embedding = Array.isArray(jobEmbeddings) ? jobEmbeddings[index] : null;
      const aiScore = embeddingScore(profileEmbedding, embedding);
      const reasons = buildReasons(profileSignals, job);

      return {
        jobId: job.id,
        job,
        score: clampScore(baseScore + aiScore),
        reasons
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

function embeddingScore(profileEmbedding, jobEmbedding) {
  if (!Array.isArray(profileEmbedding) || !Array.isArray(jobEmbedding)) {
    return 0;
  }

  const similarity = cosineSimilarity(profileEmbedding, jobEmbedding);
  const scaled = similarity * 20;
  return Math.max(0, scaled);
}

function cosineSimilarity(a, b) {
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

function buildReasons(profileSignals, job) {
  if (!profileSignals || !job) {
    return [];
  }

  const jobText = [
    job.title,
    job.description,
    job.occupationLabel,
    job.municipality
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  const sources = [
    profileSignals.occupations || [],
    profileSignals.keywords || [],
    profileSignals.seniorityHints || [],
    profileSignals.locations || []
  ];

  const reasons = [];
  const seen = new Set();
  for (const list of sources) {
    for (const term of list) {
      const value = String(term).trim();
      if (!value) {
        continue;
      }
      const key = value.toLowerCase();
      if (seen.has(key)) {
        continue;
      }
      if (jobText.includes(key)) {
        seen.add(key);
        reasons.push(value);
      }
      if (reasons.length >= 5) {
        return reasons;
      }
    }
  }

  return reasons;
}

function clampScore(value) {
  return Math.min(Math.max(value, 0), 100);
}

module.exports = { rankMatches };
