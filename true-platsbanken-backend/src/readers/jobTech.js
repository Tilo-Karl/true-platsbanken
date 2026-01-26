const { JOBTECH_CONFIG } = require('../config/jobtech');

async function fetchJobTechJobs(options = {}) {
  const limit = Math.min(
    Math.max(Number(options.limit) || JOBTECH_CONFIG.DEFAULT_LIMIT, 1),
    JOBTECH_CONFIG.MAX_LIMIT
  );
  const offset = Math.max(Number(options.offset) || 0, 0);

  const url = new URL(`${JOBTECH_CONFIG.BASE_URL}${JOBTECH_CONFIG.SEARCH_PATH}`);
  url.searchParams.set('offset', String(offset));
  url.searchParams.set('limit', String(limit));

  const response = await fetch(url.toString(), {
    headers: JOBTECH_CONFIG.DEFAULT_HEADERS
  });

  if (!response.ok) {
    throw new Error(`JobTech API error: ${response.status} ${response.statusText}`);
  }

  const payload = await response.json();
  const hits = Array.isArray(payload?.hits) ? payload.hits : [];

  return { hits, offset, limit };
}

module.exports = { fetchJobTechJobs };
