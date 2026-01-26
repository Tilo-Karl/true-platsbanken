function buildMatchReasons(profileSignals, job, limit = 5) {
  if (!profileSignals || !job) {
    return [];
  }

  const jobText = [
    job.title,
    job.description,
    job.occupationLabel,
    job.municipality
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  const sources = [
    profileSignals.occupations || [],
    profileSignals.keywords || [],
    profileSignals.seniorityHints || [],
    profileSignals.locations || []
  ];

  const reasons = [];
  const seen = new Set();
  for (const list of sources) {
    for (const term of list) {
      const value = String(term).trim();
      if (!value) {
        continue;
      }
      const key = value.toLowerCase();
      if (seen.has(key)) {
        continue;
      }
      if (jobText.includes(key)) {
        seen.add(key);
        reasons.push(value);
      }
      if (reasons.length >= limit) {
        return reasons;
      }
    }
  }

  return reasons;
}

module.exports = { buildMatchReasons };
