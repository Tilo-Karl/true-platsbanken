const { fetchJobTechJobs } = require('../../readers/jobTech');
const { normalizeJobTech } = require('./normalizeJobTech');

async function listJobTechJobs(options = {}) {
  const { hits, offset, limit } = await fetchJobTechJobs(options);
  const jobs = hits
    .map(normalizeJobTech)
    .filter(Boolean);

  const nextCursor = hits.length >= limit ? String(offset + limit) : null;

  return { jobs, nextCursor, count: jobs.length };
}

module.exports = { listJobTechJobs };
