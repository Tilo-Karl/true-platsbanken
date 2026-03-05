const TAXONOMY_BASE_URL = 'https://taxonomy.api.jobtechdev.se/v1/taxonomy/main';
const CACHE_TTL_MS = 1000 * 60 * 60 * 24;

let cachedSnapshot = null;

async function getTaxonomySnapshot() {
  if (cachedSnapshot && Date.now() - cachedSnapshot.loadedAt < CACHE_TTL_MS) {
    return cachedSnapshot;
  }

  const [occupationFields, occupations] = await Promise.all([
    fetchConcepts('occupation-field'),
    fetchConcepts('occupation-name')
  ]);

  const occupationById = new Map();
  const occupationIndex = [];
  for (const occupation of occupations) {
    occupationById.set(occupation.id, occupation);
    occupationIndex.push({
      id: occupation.id,
      label: occupation.label,
      normalized: normalizeLabel(occupation.label),
      tokens: tokenize(occupation.label)
    });
  }

  const occupationToField = new Map();
  const fieldToOccupations = new Map();

  await Promise.all(
    occupationFields.map(async (field) => {
      const related = await fetchOccupationsForField(field.id, occupationById);
      const sorted = related
        .slice()
        .sort((a, b) => a.label.localeCompare(b.label, 'sv'));

      fieldToOccupations.set(field.id, sorted);
      for (const occupation of sorted) {
        if (!occupationToField.has(occupation.id)) {
          occupationToField.set(occupation.id, field.id);
        }
      }
    })
  );

  cachedSnapshot = {
    loadedAt: Date.now(),
    occupationFields,
    occupations,
    occupationIndex,
    occupationById,
    occupationToField,
    fieldToOccupations
  };

  return cachedSnapshot;
}

async function fetchConcepts(type) {
  const url = new URL(`${TAXONOMY_BASE_URL}/concepts`);
  url.searchParams.set('type', type);

  const response = await fetch(url.toString(), {
    headers: { Accept: 'application/json' }
  });
  if (!response.ok) {
    throw new Error(`JobTech taxonomy error: ${response.status} ${response.statusText}`);
  }

  const payload = await response.json();
  if (!Array.isArray(payload)) {
    return [];
  }

  return payload
    .map(item => ({
      id: item['taxonomy/id'],
      label: item['taxonomy/preferred-label']
    }))
    .filter(item => item.id && item.label);
}

async function fetchOccupationsForField(fieldId, occupationById) {
  if (!fieldId) {
    return [];
  }

  const url = new URL(`${TAXONOMY_BASE_URL}/specific/concepts/occupation-name`);
  url.searchParams.set('relation', 'related');
  url.searchParams.set('related-ids', fieldId);

  try {
    const response = await fetch(url.toString(), {
      headers: { Accept: 'application/json' }
    });
    if (!response.ok) {
      return [];
    }
    const payload = await response.json();
    if (!Array.isArray(payload)) {
      return [];
    }

    return payload
      .map(item => item['taxonomy/id'])
      .filter(Boolean)
      .map(id => occupationById.get(id))
      .filter(Boolean);
  } catch {
    return [];
  }
}

function normalizeLabel(label) {
  return String(label)
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(label) {
  return normalizeLabel(label)
    .split(' ')
    .filter(token => token.length > 1);
}

module.exports = { getTaxonomySnapshot };
