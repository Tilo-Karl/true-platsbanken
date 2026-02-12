const { fetchJobTechSuggestions } = require('../readers/jobTech');

async function listSuggestions(query = {}) {
  const q = readSingleParam(query, 'q');
  const limit = Math.min(Math.max(Number(query.limit) || 5, 1), 10);
  if (!q || String(q).trim().length < 2) {
    return { suggestions: [] };
  }

  const payload = await fetchJobTechSuggestions({
    q: String(q).trim(),
    limit
  });

  return { suggestions: normalizeSuggestions(payload).slice(0, limit) };
}

function normalizeSuggestions(payload) {
  if (!payload) return [];
  if (Array.isArray(payload)) {
    return payload.filter((item) => typeof item === 'string');
  }
  if (Array.isArray(payload.suggestions)) {
    return payload.suggestions.filter((item) => typeof item === 'string');
  }
  if (Array.isArray(payload.completions)) {
    return payload.completions
      .map((item) => (typeof item === 'string' ? item : item?.value))
      .filter((item) => typeof item === 'string');
  }
  if (Array.isArray(payload.result)) {
    return payload.result
      .map((item) => (typeof item === 'string' ? item : item?.value))
      .filter((item) => typeof item === 'string');
  }
  if (Array.isArray(payload.typeahead)) {
    return payload.typeahead
      .map((item) => (typeof item === 'string' ? item : item?.value))
      .filter((item) => typeof item === 'string');
  }
  return [];
}

function readSingleParam(query, key) {
  const value = query[key];
  if (value === undefined || value === null) return null;
  return Array.isArray(value) ? value[0] : value;
}

module.exports = { listSuggestions };
