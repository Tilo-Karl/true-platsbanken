const { requireFirestoreDb } = require('../invariants/requireFirestoreDb');
const { listJobs: readJobs } = require('../readers/jobs');

async function listJobs(db, query = {}) {
  requireFirestoreDb(db);
  return readJobs(db, query);
}

module.exports = { listJobs };
