const { requireFirestoreDb } = require('../invariants/requireFirestoreDb');
const { upsertJob } = require('../writers/jobs');
const { jobStream } = require('./jobStream');
const { normalizeJob } = require('./normalizeJob');

async function fetchAndStoreJobs(db, options = {}) {
  requireFirestoreDb(db);

  let totalWritten = 0;
  let pagesFetched = 0;

  try {
    for await (const rawJob of jobStream(options)) {
      const job = normalizeJob(rawJob);

      if (!job) {
        continue;
      }

      await upsertJob(db, job);
      totalWritten += 1;

      pagesFetched += 1;
      if (pagesFetched % 100 === 0) {
        console.log(`Processed ${pagesFetched} jobs, written ${totalWritten}`);
      }
    }
  } catch (error) {
    console.error('Error fetching jobs:', error);
    throw error;
  }

  return { totalWritten, pagesFetched };
}

module.exports = { fetchAndStoreJobs };
