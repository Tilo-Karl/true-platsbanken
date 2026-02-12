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
  if (options.q) {
    url.searchParams.set('q', String(options.q));
  }
  appendFilterParams(url.searchParams, options);

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

function appendFilterParams(params, options = {}) {
  const occupationFieldId = normalizeId(options.occupationFieldId);
  const occupationIds = normalizeIdArray(options.occupationIds);
  const municipalityIds = normalizeIdArray(options.municipalityIds);
  const employmentTypeId = normalizeId(options.employmentTypeId);
  const workingHoursTypeId = normalizeId(options.workingHoursTypeId);

  if (occupationFieldId) {
    params.append('occupation-field', occupationFieldId);
  } else {
    occupationIds.forEach((id) => params.append('occupation-name', id));
  }

  municipalityIds.forEach((id) => params.append('municipality', id));

  if (employmentTypeId) {
    params.append('employment-type', employmentTypeId);
  }

  if (workingHoursTypeId) {
    params.append('worktime-extent', workingHoursTypeId);
  }
}

function normalizeId(value) {
  if (!value) return null;
  const resolved = String(value).trim();
  return resolved.length ? resolved : null;
}

function normalizeIdArray(value) {
  if (!value) return [];
  const list = Array.isArray(value) ? value : [value];
  return list
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0);
}

async function fetchJobTechSuggestions(options = {}) {
  const limit = Math.min(Math.max(Number(options.limit) || 5, 1), 10);
  const q = options.q ? String(options.q).trim() : '';

  const url = new URL(`${JOBTECH_CONFIG.BASE_URL}${JOBTECH_CONFIG.COMPLETE_PATH}`);
  url.searchParams.set('q', q);
  url.searchParams.set('limit', String(limit));

  const response = await fetch(url.toString(), {
    headers: JOBTECH_CONFIG.DEFAULT_HEADERS
  });

  if (!response.ok) {
    throw new Error(`JobTech API error: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

module.exports = { fetchJobTechJobs, fetchJobTechSuggestions };
