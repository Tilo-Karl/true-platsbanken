const {
  PIVOT_MIN_FAMILIES,
  PIVOT_MAX_FAMILIES,
  PIVOT_JOB_TITLES_PER_FAMILY,
  PIVOT_MAX_ITEMS_PER_FAMILY,
  PIVOT_MAX_ITEMS_PER_OCCUPATION,
  PIVOT_CAPABILITY_FAMILIES,
  PIVOT_BLOCKED_PREFIXES_WITHOUT_LEGAL_EVIDENCE,
  LEGAL_EVIDENCE_PREFIXES,
  TECH_DOMAIN_PATTERNS,
  MAX_TRACK_RESULTS
} = require('./educationPathConstants');
const {
  uniqueStrings,
  tokenizeStemmed,
  matchRatio,
  scoreConfidence,
  round2,
  clamp
} = require('./educationPathHelpers');

function normalizePivotSignals({ pivotSignals, profileSignals, explicitRoles, inferredRoles }) {
  const inferredRoleSet = new Set(
    uniqueStrings(inferredRoles).map((value) => value.toLowerCase())
  );
  const baseSignals = uniqueStrings(
    Array.isArray(pivotSignals) && pivotSignals.length
      ? pivotSignals
      : profileSignals
  );

  const filteredSignals = baseSignals.filter((signal) => !inferredRoleSet.has(signal.toLowerCase()));
  return uniqueStrings([
    ...explicitRoles,
    ...filteredSignals
  ]).slice(0, 20);
}

function classifyPivotFamilies({ profileSignals, explicitRoles }) {
  const signalText = uniqueStrings([
    ...explicitRoles,
    ...(Array.isArray(profileSignals) ? profileSignals : [])
  ]).join(' ');
  const tokenSet = new Set(tokenizeStemmed(signalText));

  return PIVOT_CAPABILITY_FAMILIES
    .map((family) => {
      const matchedPrefixes = family.evidencePrefixes.filter((prefix) =>
        hasTokenPrefix(tokenSet, prefix)
      );
      const score = matchedPrefixes.length;

      return {
        ...family,
        score,
        matchedPrefixes
      };
    })
    .filter((family) => family.score > 0)
    .sort((a, b) => b.score - a.score || a.id.localeCompare(b.id))
    .slice(0, PIVOT_MAX_FAMILIES);
}

function hasTokenPrefix(tokens, prefix) {
  if (!(tokens instanceof Set) || !tokens.size) return false;
  const key = String(prefix || '').trim();
  if (!key) return false;
  for (const token of tokens) {
    if (token.startsWith(key)) return true;
  }
  return false;
}

async function buildCapabilityPivotItems({
  taxonomy,
  sourceFieldIds,
  disallowedFieldIds,
  disallowedOccupationIds,
  disallowedCourseIds,
  profileSignals,
  explicitRoles,
  explicitSet,
  fetchByJobTitle
}) {
  const selectedFamilies = classifyPivotFamilies({ profileSignals, explicitRoles });
  if (selectedFamilies.length < PIVOT_MIN_FAMILIES) {
    console.log('Education path: pivot family evidence too thin', {
      selectedFamilies: selectedFamilies.map((family) => ({
        id: family.id,
        score: family.score
      }))
    });
  }

  const hasLegalEvidence = detectLegalEvidence(profileSignals);
  const allItems = [];

  for (const family of selectedFamilies) {
    let familyItemsCount = 0;
    for (const jobTitle of family.jobTitles.slice(0, PIVOT_JOB_TITLES_PER_FAMILY)) {
      const fetched = await fetchByJobTitle({
        occupationId: `pivot:${family.id}:${jobTitle}`,
        occupationLabel: jobTitle,
        jobTitle,
        track: 'pivot',
        profileSignals,
        crossDomain: true,
        disallowedCourseIds
      });

      for (const item of fetched) {
        if (!isAllowedPivotItem({
          item,
          family,
          taxonomy,
          disallowedFieldIds,
          disallowedOccupationIds,
          sourceFieldIds,
          hasLegalEvidence,
          explicitSet
        })) {
          continue;
        }

        item.reason = buildPivotReason({
          family,
          occupationLabel: item.occupationLabel
        });
        item.confidence = scorePivotItemConfidence({
          item,
          familyScore: family.score
        });
        item._pivotFamily = family.id;
        item._pivotFamilyScore = family.score;
        allItems.push(item);
        familyItemsCount += 1;
        if (familyItemsCount >= PIVOT_MAX_ITEMS_PER_FAMILY) {
          break;
        }
      }

      if (familyItemsCount >= PIVOT_MAX_ITEMS_PER_FAMILY) {
        break;
      }
    }
  }

  return allItems;
}

function detectLegalEvidence(profileSignals) {
  const tokens = tokenizeStemmed(
    uniqueStrings(Array.isArray(profileSignals) ? profileSignals : []).join(' ')
  );
  return tokens.some((token) =>
    LEGAL_EVIDENCE_PREFIXES.some((prefix) => token.startsWith(prefix))
  );
}

function isAllowedPivotItem({
  item,
  family,
  taxonomy,
  disallowedFieldIds,
  disallowedOccupationIds,
  sourceFieldIds,
  hasLegalEvidence,
  explicitSet
}) {
  const occupationId = String(item?.occupationId || '').trim();
  if (!occupationId) return false;
  if (explicitSet?.has(occupationId)) return false;
  if (disallowedOccupationIds?.has(occupationId)) return false;

  const fieldId = taxonomy.occupationToField.get(occupationId);
  if (!fieldId) return false;
  if (sourceFieldIds?.has(fieldId)) return false;
  if (disallowedFieldIds?.has(fieldId)) return false;

  const roleTokens = tokenizeStemmed(`${item.occupationLabel || ''} ${item.courseTitle || ''}`);
  const technicalShare = matchRatio(roleTokens, TECH_DOMAIN_PATTERNS);
  if (technicalShare >= 0.34) return false;

  if (!hasLegalEvidence) {
    const hasBlockedPrefix = roleTokens.some((token) =>
      PIVOT_BLOCKED_PREFIXES_WITHOUT_LEGAL_EVIDENCE.some((prefix) => token.startsWith(prefix))
    );
    if (hasBlockedPrefix) return false;
  }

  const familyMatch = roleTokens.some((token) =>
    family.targetPrefixes.some((prefix) => token.startsWith(prefix))
  );
  if (!familyMatch) return false;

  return true;
}

function buildPivotReason({ family, occupationLabel }) {
  return `Transferable ${family.label.toLowerCase()} signals support ${occupationLabel} as a realistic pivot path.`;
}

function scorePivotItemConfidence({ item, familyScore }) {
  const base = scoreConfidence({
    track: 'pivot',
    startDate: item.startDate,
    duration: item.duration,
    provider: item.provider,
    crossDomain: true
  });

  const familyBoost = Math.min(0.12, Math.max(0, familyScore - 1) * 0.03);
  return round2(clamp(base + familyBoost, 0, 0.98));
}

function selectBalancedPivotItems(items) {
  if (!Array.isArray(items) || !items.length) return [];

  const ordered = items.slice().sort((a, b) => {
    const familyDelta = (b._pivotFamilyScore || 0) - (a._pivotFamilyScore || 0);
    if (familyDelta !== 0) return familyDelta;
    if (b.confidence !== a.confidence) return b.confidence - a.confidence;
    return a._startSort - b._startSort;
  });

  const byFamily = new Map();
  for (const item of ordered) {
    const familyId = String(item._pivotFamily || 'unknown');
    if (!byFamily.has(familyId)) byFamily.set(familyId, []);
    byFamily.get(familyId).push(item);
  }

  const familyOrder = Array.from(byFamily.entries())
    .sort((a, b) => {
      const aScore = a[1][0]?._pivotFamilyScore || 0;
      const bScore = b[1][0]?._pivotFamilyScore || 0;
      return bScore - aScore;
    })
    .map(([familyId]) => familyId);

  const result = [];
  const perFamilyCount = new Map();
  const perOccupationCount = new Map();
  let exhaustedFamilies = 0;

  while (result.length < MAX_TRACK_RESULTS && exhaustedFamilies < familyOrder.length) {
    exhaustedFamilies = 0;

    for (const familyId of familyOrder) {
      const queue = byFamily.get(familyId);
      if (!queue?.length) {
        exhaustedFamilies += 1;
        continue;
      }

      const familyCount = perFamilyCount.get(familyId) || 0;
      if (familyCount >= PIVOT_MAX_ITEMS_PER_FAMILY) {
        exhaustedFamilies += 1;
        continue;
      }

      let picked = null;
      while (queue.length) {
        const candidate = queue.shift();
        const occupationId = String(candidate.occupationId || '').trim();
        const occupationCount = perOccupationCount.get(occupationId) || 0;
        if (occupationCount >= PIVOT_MAX_ITEMS_PER_OCCUPATION) {
          continue;
        }
        picked = candidate;
        break;
      }

      if (!picked) {
        exhaustedFamilies += 1;
        continue;
      }

      result.push(picked);
      perFamilyCount.set(familyId, familyCount + 1);
      const occupationId = String(picked.occupationId || '').trim();
      perOccupationCount.set(occupationId, (perOccupationCount.get(occupationId) || 0) + 1);

      if (result.length >= MAX_TRACK_RESULTS) break;
    }
  }

  return result;
}

function deriveSourceFieldIds({ explicitOccupationIds, inferredOccupationIds, taxonomy }) {
  const baseIds = explicitOccupationIds.length ? explicitOccupationIds : inferredOccupationIds;
  return new Set(
    baseIds
      .map((id) => taxonomy.occupationToField.get(id))
      .filter(Boolean)
  );
}

module.exports = {
  normalizePivotSignals,
  buildCapabilityPivotItems,
  selectBalancedPivotItems,
  deriveSourceFieldIds
};
