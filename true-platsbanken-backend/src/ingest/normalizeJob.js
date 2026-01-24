function mapEmploymentType(label) {
  if (!label) return 'unknown';
  const normalized = String(label).toLowerCase();
  if (normalized.includes('full') || normalized.includes('heltid')) {
    return 'full_time';
  }
  if (normalized.includes('part') || normalized.includes('deltid')) {
    return 'part_time';
  }
  return 'unknown';
}

function normalizeJob(raw) {
  const title = raw.headline || '';
  const publishedAtRaw = raw.publication_date;
  const publishedDate = new Date(publishedAtRaw);
  const publishedAt = Number.isNaN(publishedDate.getTime())
    ? new Date().toISOString()
    : publishedDate.toISOString();
  const id = String(raw.id || '');
  const applicationDeadlineRaw = raw.application_deadline;
  const applicationDeadlineDate = new Date(applicationDeadlineRaw);
  const applicationDeadline = applicationDeadlineRaw
    ? (Number.isNaN(applicationDeadlineDate.getTime())
      ? String(applicationDeadlineRaw)
      : applicationDeadlineDate.toISOString())
    : null;
  const scopeOfWork = raw?.scope_of_work
    ? {
      min: raw.scope_of_work.min ?? null,
      max: raw.scope_of_work.max ?? null,
      label: raw.scope_of_work.label ?? null
    }
    : null;

  if (!id) {
    return null;
  }

  return {
    id,
    source: 'platsbanken',
    url: String(raw.webpage_url || ''),
    title: String(title),
    description: String(raw?.description?.text || ''),
    employerName: String(raw?.employer?.name || ''),
    municipality: String(raw?.workplace_address?.municipality || ''),
    publishedAt,
    employmentType: mapEmploymentType(raw?.employment_type?.label),
    employmentTypeLabel: raw?.employment_type?.label ? String(raw.employment_type.label) : null,
    durationLabel: raw?.duration?.label ? String(raw.duration.label) : null,
    scopeOfWork,
    applicationDeadline,
    numberOfVacancies: Number.isFinite(Number(raw?.number_of_vacancies))
      ? Number(raw.number_of_vacancies)
      : null,
    occupationLabel: raw?.occupation?.label ? String(raw.occupation.label) : null,
    remotePossible: null
  };
}

module.exports = { normalizeJob };
