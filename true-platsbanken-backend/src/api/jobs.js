const { listJobTechJobs } = require('../domain/jobs/jobTechJobs');

async function listJobs(db, query = {}) {
  const occupationIds = readArrayParam(query, 'occupation_ids');
  const municipalityIds = readArrayParam(query, 'municipality_ids');
  const occupationFieldId = readSingleParam(query, 'occupation_field_id');
  const employmentTypeId = readSingleParam(query, 'employment_type_id');
  const workingHoursTypeId = readSingleParam(query, 'working_hours_type_id');
  const textQuery = readSingleParam(query, 'q');

  console.log('[jobs] query', {
    occupationIds,
    municipalityIds,
    occupationFieldId,
    employmentTypeId,
    workingHoursTypeId,
    q: textQuery,
    offset: query.offset ?? query.cursor ?? null,
    limit: query.limit ?? null
  });

  return listJobTechJobs({
    offset: query.offset ?? query.cursor,
    limit: query.limit,
    occupationIds,
    municipalityIds,
    occupationFieldId,
    employmentTypeId,
    workingHoursTypeId,
    q: textQuery
  });
}

function readArrayParam(query, key) {
  const direct = query[key];
  const bracketed = query[`${key}[]`];
  const value = direct ?? bracketed;
  if (!value) return [];
  return Array.isArray(value) ? value : [value];
}

function readSingleParam(query, key) {
  const value = query[key];
  if (value === undefined || value === null) return null;
  return Array.isArray(value) ? value[0] : value;
}

module.exports = { listJobs };
