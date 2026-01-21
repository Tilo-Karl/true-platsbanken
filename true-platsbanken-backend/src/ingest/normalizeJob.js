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

  return {
    id: String(raw.id || ''),
    source: 'platsbanken',
    url: String(raw.webpage_url || ''),
    title: String(title),
    description: String(raw?.description?.text || ''),
    employerName: String(raw?.employer?.name || ''),
    municipality: String(raw?.workplace_address?.municipality || ''),
    publishedAt,
    employmentType: mapEmploymentType(raw?.employment_type?.label),
    remotePossible: null
  };
}

module.exports = { normalizeJob };