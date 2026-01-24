function extractProfileSignals(skillsText, cvText, employmentPreferences) {
  const keywords = uniquePreservingOrder([
    ...tokenize(skillsText),
    ...tokenize(cvText)
  ]);

  const occupations = uniquePreservingOrder([
    ...extractLabeledValues(skillsText, ['occupation:', 'role:', 'yrke:', 'roll:']),
    ...extractLabeledValues(cvText, ['occupation:', 'role:', 'yrke:', 'roll:'])
  ]);

  const locations = uniquePreservingOrder([
    ...normalizeLocation(employmentPreferences.municipality),
    ...extractLabeledValues(skillsText, ['location:', 'ort:', 'plats:', 'stad:']),
    ...extractLabeledValues(cvText, ['location:', 'ort:', 'plats:', 'stad:'])
  ]);

  const seniorityHints = uniquePreservingOrder([
    ...extractSeniorityHints(skillsText),
    ...extractSeniorityHints(cvText)
  ]);

  const constraints = {
    employmentType: normalizeEmploymentType(employmentPreferences.employmentType),
    locations
  };

  return {
    keywords,
    occupations,
    locations,
    seniorityHints,
    constraints
  };
}

function normalizeEmploymentType(value) {
  if (!value) {
    return null;
  }
  const trimmed = String(value).trim();
  if (!trimmed || trimmed === 'any') {
    return null;
  }
  return trimmed;
}

function tokenize(text) {
  if (!text) {
    return [];
  }
  const lower = String(text).toLowerCase();
  const parts = lower.split(/[^\p{L}\p{N}]+/u);
  return parts
    .map(part => part.trim())
    .filter(part => part.length >= 2);
}

function extractLabeledValues(text, labels) {
  if (!text) {
    return [];
  }
  const lines = String(text).split(/\r?\n/);
  const results = [];
  for (const line of lines) {
    const trimmed = line.trim();
    const lower = trimmed.toLowerCase();
    for (const label of labels) {
      if (lower.startsWith(label)) {
        const value = trimmed.slice(label.length).trim();
        if (value) {
          results.push(value);
        }
      }
    }
  }
  return results;
}

function extractSeniorityHints(text) {
  const tokens = tokenize(text);
  const hints = [
    'junior',
    'senior',
    'lead',
    'principal',
    'staff',
    'manager',
    'chef',
    'ansvarig'
  ];
  const results = [];
  for (const hint of hints) {
    if (tokens.includes(hint)) {
      results.push(hint);
    }
  }
  return results;
}

function normalizeLocation(value) {
  if (!value) {
    return [];
  }
  const trimmed = String(value).trim();
  return trimmed ? [trimmed] : [];
}

function uniquePreservingOrder(values) {
  const seen = new Set();
  const result = [];
  for (const value of values) {
    const key = String(value).trim();
    if (!key || seen.has(key)) {
      continue;
    }
    seen.add(key);
    result.push(key);
  }
  return result;
}

module.exports = { extractProfileSignals };
