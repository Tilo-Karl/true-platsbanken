function buildProfileEmbeddingText(profileSignals) {
  if (!profileSignals) {
    return '';
  }

  return []
    .concat(
      profileSignals.keywords || [],
      profileSignals.occupations || [],
      profileSignals.seniorityHints || [],
      profileSignals.locations || []
    )
    .filter(Boolean)
    .join(' ');
}

function buildJobEmbeddingText(job) {
  if (!job) {
    return '';
  }

  return [job.title, job.description, job.occupationLabel, job.municipality]
    .filter(Boolean)
    .join(' ');
}

function buildEmbeddingInputs(profileSignals, jobs) {
  const profileText = buildProfileEmbeddingText(profileSignals);
  const jobTexts = Array.isArray(jobs) ? jobs.map(buildJobEmbeddingText) : [];
  return { profileText, jobTexts, inputs: [profileText, ...jobTexts] };
}

function extractEmbeddings(payload) {
  if (!payload || !Array.isArray(payload.data)) {
    return { profileEmbedding: null, jobEmbeddings: [] };
  }

  const embeddings = payload.data.map(item => item.embedding);
  return {
    profileEmbedding: embeddings[0] || null,
    jobEmbeddings: embeddings.slice(1)
  };
}

module.exports = {
  buildProfileEmbeddingText,
  buildJobEmbeddingText,
  buildEmbeddingInputs,
  extractEmbeddings
};
