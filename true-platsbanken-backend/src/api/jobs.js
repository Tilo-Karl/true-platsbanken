const { listJobTechJobs } = require('../domain/jobs/jobTechJobs');

async function listJobs(db, query = {}) {
  return listJobTechJobs({
    offset: query.cursor,
    limit: query.limit
  });
}

module.exports = { listJobs };
