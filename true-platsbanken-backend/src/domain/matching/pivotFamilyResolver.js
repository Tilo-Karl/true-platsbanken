const { uniqueCaseInsensitiveStrings } = require('../shared/uniqueCaseInsensitiveStrings');

function buildPivotFamilyMatchers(opportunityProfile) {
  const families = Array.isArray(opportunityProfile?.pivotOpportunityFamilies)
    ? opportunityProfile.pivotOpportunityFamilies
    : [];

  return families.map((family) => {
    const patterns = uniqueStrings([
      family?.label,
      ...(Array.isArray(family?.searchTerms) ? family.searchTerms : []),
      ...(Array.isArray(family?.occupationSeeds) ? family.occupationSeeds : [])
    ]).map(normalizeText).filter((value) => value.length >= 3);

    return {
      id: String(family?.id || ''),
      label: String(family?.label || ''),
      fitScore: Number(family?.fitScore || 0),
      patterns
    };
  }).filter((family) => family.id && family.patterns.length);
}

function resolvePivotFamily(match, families) {
  const directFamily = normalizePivotFamily(match?.pivotFamily || match?.job?._pivotFamily);
  const inferredFamily = inferPivotFamily(match?.job, families);

  if (!directFamily) {
    return inferredFamily;
  }
  if (!inferredFamily) {
    return directFamily;
  }

  // Pivot pools can include overlapping jobs from different family queries.
  // If title/group evidence clearly points to another family, prefer inference.
  if (inferredFamily.id !== directFamily.id && inferredFamily.score >= 2) {
    return {
      id: inferredFamily.id,
      label: inferredFamily.label,
      fitScore: inferredFamily.fitScore
    };
  }

  return directFamily;
}

function normalizePivotFamily(family) {
  const id = String(family?.id || '').trim();
  const label = String(family?.label || '').trim();
  if (!id || !label) return null;
  return {
    id,
    label,
    fitScore: Number(family?.fitScore || 0)
  };
}

function inferPivotFamily(job, families) {
  if (!Array.isArray(families) || !families.length) {
    return null;
  }
  const text = normalizeText([
    job?.title,
    job?.occupationLabel,
    job?.occupationGroupLabel
  ].filter(Boolean).join(' '));

  let best = null;
  for (const family of families) {
    let score = 0;
    for (const pattern of family.patterns) {
      if (!pattern) continue;
      if (text.includes(pattern)) {
        score += Math.min(3, pattern.split(' ').length);
      }
    }
    if (!score) continue;
    if (!best || score > best.score) {
      best = { id: family.id, label: family.label, fitScore: family.fitScore, score };
    }
  }

  return best;
}

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function uniqueStrings(values) {
  return uniqueCaseInsensitiveStrings(values);
}

module.exports = { buildPivotFamilyMatchers, resolvePivotFamily };
