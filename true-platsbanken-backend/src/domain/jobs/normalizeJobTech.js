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

function normalizeJobTech(raw) {
  const id = String(raw?.id || '');
  if (!id) {
    return null;
  }

  const publishedAtRaw = raw?.publication_date;
  const publishedDate = new Date(publishedAtRaw);
  const publishedAt = Number.isNaN(publishedDate.getTime())
    ? new Date().toISOString()
    : publishedDate.toISOString();

  const applicationDeadlineRaw = raw?.application_deadline;
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

  return {
    id,
    source: 'platsbanken',
    url: String(raw?.webpage_url || ''),
    title: String(raw?.headline || ''),
    description: String(raw?.description?.text || ''),
    employerName: String(raw?.employer?.name || ''),
    employerWorkplace: raw?.employer?.workplace ? String(raw.employer.workplace) : null,
    municipality: String(raw?.workplace_address?.municipality || ''),
    publishedAt,
    employmentType: mapEmploymentType(raw?.employment_type?.label),
    employmentTypeLabel: raw?.employment_type?.label ? String(raw.employment_type.label) : null,
    workingHoursTypeLabel: raw?.working_hours_type?.label ? String(raw.working_hours_type.label) : null,
    durationLabel: raw?.duration?.label ? String(raw.duration.label) : null,
    scopeOfWorkLabel: raw?.scope_of_work?.label ? String(raw.scope_of_work.label) : null,
    scopeOfWork,
    salaryDescription: raw?.salary_description ? String(raw.salary_description) : null,
    conditions: raw?.description?.conditions ? String(raw.description.conditions) : null,
    applicationDetailsUrl: raw?.application_details?.url
      ? String(raw.application_details.url)
      : null,
    logoUrl: raw?.logo_url ? String(raw.logo_url) : null,
    lastPublicationDate: raw?.last_publication_date ? String(raw.last_publication_date) : null,
    applicationDeadline,
    numberOfVacancies: Number.isFinite(Number(raw?.number_of_vacancies))
      ? Number(raw.number_of_vacancies)
      : null,
    occupationLabel: raw?.occupation?.label ? String(raw.occupation.label) : null,
    occupationGroupLabel: raw?.occupation_group?.label ? String(raw.occupation_group.label) : null,
    occupationFieldLabel: raw?.occupation_field?.label ? String(raw.occupation_field.label) : null,
    remotePossible: null
  };
}

module.exports = { normalizeJobTech };
