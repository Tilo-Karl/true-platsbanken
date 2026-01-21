const { jobStream } = require('./jobStream');
const { normalizeJob } = require('./normalizeJob');

async function fetchAndStoreJobs(db, options = {}) {
  if (!db) {
    throw new Error('Firestore db is required');
  }

  let totalWritten = 0;
  let pagesFetched = 0;

  try {
    for await (const rawJob of jobStream(options)) {
      const job = normalizeJob(rawJob);

      if (!job.id) {
        continue;
      }

      const docRef = db.collection('jobs').doc(job.id);
      await docRef.set(job, { merge: true });
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