const { JOBTECH_CONFIG } = require('../config/jobtech');

async function* jobStream(options = {}) {
  const {
    limit = JOBTECH_CONFIG.DEFAULT_LIMIT,
    publishedAfter = null,
    publishedBefore = null
  } = options;

  let offset = 0;
  let hasMore = true;

  while (hasMore) {
    const url = new URL(`${JOBTECH_CONFIG.BASE_URL}${JOBTECH_CONFIG.SEARCH_PATH}`);
    url.searchParams.set('offset', String(offset));
    url.searchParams.set('limit', String(limit));

    if (publishedAfter) {
      url.searchParams.set('published-after', publishedAfter);
    }
    if (publishedBefore) {
      url.searchParams.set('published-before', publishedBefore);
    }

    const response = await fetch(url.toString(), {
      headers: JOBTECH_CONFIG.DEFAULT_HEADERS
    });

    if (!response.ok) {
      throw new Error(`JobTech API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    const hits = Array.isArray(data?.hits) ? data.hits : [];

    if (hits.length === 0) {
      hasMore = false;
      break;
    }

    for (const hit of hits) {
      yield hit;
    }

    if (hits.length < limit) {
      hasMore = false;
    }

    offset += limit;
  }
}

module.exports = { jobStream };