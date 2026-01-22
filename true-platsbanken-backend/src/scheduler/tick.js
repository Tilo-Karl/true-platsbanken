const { fetchAndStoreJobs } = require('../ingest/fetchJobs');

async function tick(db) {
  const startTime = Date.now();
  console.log('[tick] Starting job ingestion at', new Date().toISOString());

  try {
    const result = await fetchAndStoreJobs(db);
    const duration = Date.now() - startTime;

    console.log(`[tick] Completed in ${duration}ms: ${result.totalWritten} written, ${result.pagesFetched} processed`);

    return {
      success: true,
      totalWritten: result.totalWritten,
      pagesFetched: result.pagesFetched,
      duration,
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error(`[tick] Failed after ${duration}ms:`, error.message);

    return {
      success: false,
      error: error.message,
      duration,
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = { tick };
