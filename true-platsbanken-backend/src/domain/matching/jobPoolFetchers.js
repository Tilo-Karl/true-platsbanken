const { listJobTechJobs } = require('../jobs/jobTechJobs');
const { filterJobsByMunicipality } = require('../jobs/filterJobs');

async function fetchJobsForOccupationIds(occupationIds, options) {
  if (!occupationIds.length) {
    return { pool: [], perOccupationCounts: {} };
  }

  const tasks = occupationIds.map(id =>
    listJobTechJobs({
      occupationIds: [id],
      limit: options.perOccupationLimit
    })
  );

  const responses = await Promise.all(tasks);
  const seen = new Set();
  const results = [];
  const perOccupationCounts = {};

  for (let index = 0; index < responses.length; index += 1) {
    const response = responses[index];
    const occupationId = occupationIds[index];
    const jobs = options.municipality
      ? filterJobsByMunicipality(response.jobs, options.municipality)
      : response.jobs;

    perOccupationCounts[occupationId] = jobs.length;

    for (const job of jobs) {
      if (!job || !job.id) continue;
      if (seen.has(job.id)) continue;
      seen.add(job.id);
      const mappedJob = typeof options.decorateJob === 'function'
        ? options.decorateJob(job, occupationId)
        : job;
      if (!mappedJob || !mappedJob.id) continue;
      results.push(mappedJob);
      if (results.length >= options.maxPool) {
        return { pool: results, perOccupationCounts };
      }
    }
  }

  return { pool: results, perOccupationCounts };
}

async function fetchJobsForQueries(queries, options) {
  if (!queries.length) {
    return [];
  }

  const tasks = queries.map(query =>
    listJobTechJobs({
      q: query,
      limit: options.perQueryLimit
    })
  );

  const responses = await Promise.all(tasks);
  const seen = new Set();
  const results = [];

  for (const response of responses) {
    const jobs = options.municipality
      ? filterJobsByMunicipality(response.jobs, options.municipality)
      : response.jobs;

    for (const job of jobs) {
      if (!job || !job.id) continue;
      if (seen.has(job.id)) continue;
      seen.add(job.id);
      const mappedJob = typeof options.decorateJob === 'function'
        ? options.decorateJob(job, response)
        : job;
      if (!mappedJob || !mappedJob.id) continue;
      results.push(mappedJob);
      if (results.length >= options.maxPool) {
        return results;
      }
    }
  }

  return results;
}

module.exports = { fetchJobsForOccupationIds, fetchJobsForQueries };
