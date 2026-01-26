function filterJobsByMunicipality(jobs, municipality) {
  if (!municipality) {
    return jobs;
  }

  const target = String(municipality).toLowerCase();
  return jobs.filter(job => String(job?.municipality || '').toLowerCase() === target);
}

module.exports = { filterJobsByMunicipality };
