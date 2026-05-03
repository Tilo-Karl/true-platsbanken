const { fetchJobEdConnect } = require('../../readers/jobEdConnect');
const { getTaxonomySnapshot } = require('../taxonomy/jobTechTaxonomy');

const MAX_TRACK_RESULTS = 5;
const MAX_OCCUPATIONS_PER_TRACK = 12;
const MAX_EDUCATIONS_PER_OCCUPATION = 8;
const MIN_STRENGTHEN_RESULTS = 2;
const PIVOT_MIN_FAMILIES = 3;
const PIVOT_MAX_FAMILIES = 5;
const PIVOT_JOB_TITLES_PER_FAMILY = 2;
const PIVOT_MAX_ITEMS_PER_FAMILY = 2;
const PIVOT_MAX_ITEMS_PER_OCCUPATION = 1;

const PIVOT_CAPABILITY_FAMILIES = [
  {
    id: 'delivery_coordination',
    label: 'Delivery and coordination',
    evidencePrefixes: ['agil', 'scrum', 'roadmap', 'team', 'lead', 'stakeholder', 'projekt', 'plan'],
    targetPrefixes: ['projektled', 'samordn', 'processled', 'teamled', 'verksamhetsutveckl'],
    jobTitles: ['projektledare', 'processledare', 'samordnare']
  },
  {
    id: 'analysis_improvement',
    label: 'Analysis and improvement',
    evidencePrefixes: ['analys', 'data', 'kpi', 'rapport', 'roadmap', 'prioriter', 'strateg', 'förbättr'],
    targetPrefixes: ['analys', 'controller', 'utred', 'verksamhets', 'planer'],
    jobTitles: ['verksamhetsanalytiker', 'business analyst', 'controller']
  },
  {
    id: 'customer_commercial',
    label: 'Customer and commercial',
    evidencePrefixes: ['stakeholder', 'kund', 'kommun', 'relation', 'rådgiv', 'förhandl', 'sales', 'commercial'],
    targetPrefixes: ['kund', 'sälj', 'account', 'rådgiv', 'affär'],
    jobTitles: ['kundrådgivare', 'account manager', 'säljkoordinator']
  },
  {
    id: 'operations_planning',
    label: 'Operations and planning',
    evidencePrefixes: ['drift', 'leverans', 'plan', 'koord', 'resurs', 'flöd', 'support', 'incident'],
    targetPrefixes: ['logistik', 'produktion', 'inköp', 'planer', 'drift'],
    jobTitles: ['logistiker', 'produktionsplanerare', 'inköpare']
  },
  {
    id: 'quality_governance',
    label: 'Quality and governance',
    evidencePrefixes: ['kvalitet', 'process', 'risk', 'itil', 'säker', 'compliance', 'standard', 'revision'],
    targetPrefixes: ['kvalitet', 'miljö', 'säker', 'upphandling', 'revision'],
    jobTitles: ['kvalitetssamordnare', 'kvalitetstekniker', 'upphandlare']
  },
  {
    id: 'people_enablement',
    label: 'People enablement',
    evidencePrefixes: ['coach', 'handled', 'utbild', 'mento', 'facilit', 'onboard', 'ledning', 'team'],
    targetPrefixes: ['utbild', 'handled', 'coach', 'lärare', 'instrukt'],
    jobTitles: ['utbildningskoordinator', 'handledare', 'yrkeslärare']
  }
];

const PIVOT_BLOCKED_PREFIXES_WITHOUT_LEGAL_EVIDENCE = [
  'paralegal',
  'jurist',
  'jurid',
  'legal',
  'advokat',
  'administrat',
  'admin',
  'sekreter',
  'registrator',
  'handlägg',
  'case'
];

const LEGAL_EVIDENCE_PREFIXES = [
  'jurid',
  'legal',
  'compliance',
  'regelefterlev',
  'avtal',
  'upphandling',
  'case',
  'ärende',
  'handlägg'
];

const TECH_DOMAIN_PATTERNS = [
  'it',
  'tech',
  'tekn',
  'dev',
  'utveckl',
  'system',
  'mjukvar',
  'programmer',
  'backend',
  'frontend',
  'fullstack',
  'ios',
  'android',
  'cloud',
  'data',
  'databas',
  'ai',
  'api',
  'scrum',
  'agil'
];

async function resolveEducationPaths(input = {}) {
  const explicitOccupationIds = uniqueIds(input.explicitOccupationIds);
  const inferredOccupationIds = uniqueIds(input.inferredOccupationIds);
  const explicitRoles = uniqueStrings(input.explicitRoles);
  const inferredRoles = uniqueStrings(input.inferredRoles);
  const inferredRoleDetails = Array.isArray(input.inferredRoleDetails) ? input.inferredRoleDetails : [];
  const profileSignals = normalizeSignals(input.profileSignals, explicitRoles, inferredRoles, inferredRoleDetails);

  if (!explicitOccupationIds.length && !inferredOccupationIds.length) {
    return { strengthen: [], pivot: [] };
  }

  const taxonomy = await getTaxonomySnapshot();
  const explicitSet = new Set(explicitOccupationIds);

  const strengthenOccupationIds = uniqueIds([
    ...explicitOccupationIds,
    ...inferredOccupationIds
  ]).slice(0, MAX_OCCUPATIONS_PER_TRACK);

  const strengthenRaw = await buildTrackItems({
    track: 'strengthen',
    occupationIds: strengthenOccupationIds,
    taxonomy,
    explicitSet,
    profileSignals
  });

  let strengthen = dedupeAndRankTrack(strengthenRaw).slice(0, MAX_TRACK_RESULTS);
  if (strengthen.length < MIN_STRENGTHEN_RESULTS) {
    const strengthenUsedCourseIds = new Set(
      strengthen
        .map((item) => item._courseId)
        .filter(Boolean)
    );

    const roleFallbackRaw = await buildStrengthenRoleFallbackItems({
      explicitRoles,
      inferredRoles,
      profileSignals,
      disallowedCourseIds: strengthenUsedCourseIds
    });

    strengthen = dedupeAndRankTrack([
      ...strengthen,
      ...roleFallbackRaw
    ]).slice(0, MAX_TRACK_RESULTS);
  }

  const strengthenResolvedOccupationIds = new Set(
    strengthen
      .map((item) => String(item.occupationId || '').trim())
      .filter(Boolean)
  );
  const usedCourseIds = new Set(strengthen.map((item) => item._courseId).filter(Boolean));

  const sourceFieldIds = deriveSourceFieldIds({
    explicitOccupationIds,
    inferredOccupationIds: [],
    taxonomy
  });
  if (!sourceFieldIds.size) {
    const inferredSourceFieldIds = deriveSourceFieldIds({
      explicitOccupationIds: [],
      inferredOccupationIds,
      taxonomy
    });
    for (const fieldId of inferredSourceFieldIds) {
      sourceFieldIds.add(fieldId);
    }
  }

  const disallowedPivotFieldIds = new Set(
    strengthen
      .map((item) => taxonomy.occupationToField.get(item.occupationId))
      .filter(Boolean)
  );
  for (const sourceFieldId of sourceFieldIds) {
    disallowedPivotFieldIds.add(sourceFieldId);
  }

  const pivotSignals = normalizePivotSignals({
    pivotSignals: input.pivotSignals,
    profileSignals: input.profileSignals,
    explicitRoles,
    inferredRoles
  });

  const pivotRaw = await buildCapabilityPivotItems({
    taxonomy,
    sourceFieldIds,
    disallowedFieldIds: disallowedPivotFieldIds,
    disallowedOccupationIds: strengthenResolvedOccupationIds,
    disallowedCourseIds: usedCourseIds,
    profileSignals: pivotSignals,
    explicitRoles,
    explicitSet
  });

  const pivotRanked = dedupeAndRankTrack(pivotRaw);
  const pivot = selectBalancedPivotItems(pivotRanked).slice(0, MAX_TRACK_RESULTS);

  await enrichMissingCourseUrls([...strengthen, ...pivot]);

  return {
    strengthen: strengthen.map(stripInternalFields),
    pivot: pivot.map(stripInternalFields)
  };
}

async function buildStrengthenRoleFallbackItems({
  explicitRoles,
  inferredRoles,
  profileSignals,
  disallowedCourseIds
}) {
  const roleTitles = buildSignalJobTitles('', uniqueStrings([
    ...explicitRoles,
    ...inferredRoles,
    ...(Array.isArray(profileSignals) ? profileSignals : [])
  ]));

  const items = [];
  for (const roleTitle of roleTitles) {
    const fetched = await fetchEducationsByJobTitle({
      occupationId: roleTitle,
      occupationLabel: roleTitle,
      jobTitle: roleTitle,
      track: 'strengthen',
      profileSignals,
      crossDomain: false,
      disallowedCourseIds
    });
    items.push(...fetched);
    if (items.length >= MAX_TRACK_RESULTS) break;
  }

  return items;
}

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

  const scoredFamilies = PIVOT_CAPABILITY_FAMILIES
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

  return scoredFamilies;
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
  explicitSet
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
      const fetched = await fetchEducationsByJobTitle({
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

async function buildTrackItems({
  track,
  occupationIds,
  taxonomy,
  explicitSet,
  profileSignals,
  disallowedOccupationIds = new Set(),
  disallowedFieldIds = new Set(),
  disallowedCourseIds = new Set()
}) {
  const allItems = [];
  for (const occupationId of occupationIds) {
    if (disallowedOccupationIds.has(occupationId)) continue;
    const fieldId = taxonomy.occupationToField.get(occupationId);
    if (disallowedFieldIds.has(fieldId)) continue;

    const occupation = taxonomy.occupationById.get(occupationId);
    const occupationLabel = occupation?.label || occupationId;
    const crossDomain = !explicitSet.has(occupationId);

    const directItems = await fetchEducationsByOccupation({
      occupationId,
      occupationLabel,
      track,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });

    const titleFallbackItems = directItems.length
      ? []
      : await fetchEducationsByJobTitle({
        occupationId,
        occupationLabel,
        track,
        profileSignals,
        crossDomain,
        disallowedCourseIds
      });

    const signalTitleFallbackItems = directItems.length || titleFallbackItems.length
      ? []
      : await fetchEducationsBySignalTitles({
        occupationId,
        occupationLabel,
        track,
        profileSignals,
        crossDomain,
        disallowedCourseIds
      });

    const fallbackItems = directItems.length || titleFallbackItems.length || signalTitleFallbackItems.length
      ? []
      : await fetchEducationsByQuery({
        occupationId,
        occupationLabel,
        track,
        profileSignals,
        crossDomain,
        disallowedCourseIds
      });

    allItems.push(...directItems, ...titleFallbackItems, ...signalTitleFallbackItems, ...fallbackItems);
  }

  return allItems;
}

async function fetchEducationsByOccupation({
  occupationId,
  occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  try {
    const payload = await fetchJobEdConnect('/v1/educations/match-by-occupation', {
      method: 'POST',
      query: {
        occupation_id: occupationId,
        include_metadata: true,
        limit: MAX_EDUCATIONS_PER_OCCUPATION,
        offset: 0
      }
    });

    return mapEducationPayloadToItems({
      payload,
      track,
      occupationId,
      occupationLabel,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
  } catch (error) {
    console.log('Education path: match-by-occupation failed', {
      occupationId,
      message: error.message
    });
    return [];
  }
}

async function fetchEducationsByQuery({
  occupationId,
  occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  try {
    const payload = await fetchJobEdConnect('/v1/educations', {
      method: 'GET',
      query: {
        query: occupationLabel,
        limit: MAX_EDUCATIONS_PER_OCCUPATION,
        offset: 0
      }
    });

    return mapEducationPayloadToItems({
      payload,
      track,
      occupationId,
      occupationLabel,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
  } catch (error) {
    console.log('Education path: educations query fallback failed', {
      occupationId,
      occupationLabel,
      message: error.message
    });
    return [];
  }
}

async function fetchEducationsByJobTitle({
  occupationId,
  occupationLabel,
  jobTitle = occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  try {
    const payload = await fetchJobEdConnect('/v1/educations/match-by-jobtitle', {
      method: 'POST',
      query: {
        jobtitle: jobTitle,
        include_metadata: true,
        limit: MAX_EDUCATIONS_PER_OCCUPATION,
        offset: 0
      }
    });

    const mappedOccupation = mapOccupationFromJobTitlePayload(payload);
    const resolvedOccupationId = mappedOccupation.id || occupationId;
    const resolvedOccupationLabel = mappedOccupation.label || occupationLabel;

    return mapEducationPayloadToItems({
      payload,
      track,
      occupationId: resolvedOccupationId,
      occupationLabel: resolvedOccupationLabel,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
  } catch (error) {
    console.log('Education path: match-by-jobtitle failed', {
      occupationId,
      occupationLabel,
      jobTitle,
      message: error.message
    });
    return [];
  }
}

async function fetchEducationsBySignalTitles({
  occupationId,
  occupationLabel,
  track,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  const signalTitles = buildSignalJobTitles(occupationLabel, profileSignals);
  if (!signalTitles.length) return [];

  for (const signalTitle of signalTitles) {
    const items = await fetchEducationsByJobTitle({
      occupationId,
      occupationLabel,
      jobTitle: signalTitle,
      track,
      profileSignals,
      crossDomain,
      disallowedCourseIds
    });
    if (items.length) {
      return items;
    }
  }

  return [];
}

function mapEducationPayloadToItems({
  payload,
  track,
  occupationId,
  occupationLabel,
  profileSignals,
  crossDomain,
  disallowedCourseIds
}) {
  const results = Array.isArray(payload?.result)
    ? payload.result
    : Array.isArray(payload?.hits)
      ? payload.hits
      : [];
  const items = [];

  for (const row of results) {
    const mapped = mapEducationRow({
      row,
      track,
      occupationId,
      occupationLabel,
      profileSignals,
      crossDomain
    });

    if (!mapped) continue;
    if (disallowedCourseIds.has(mapped._courseId)) continue;
    disallowedCourseIds.add(mapped._courseId);
    items.push(mapped);
  }

  return items;
}

function mapEducationRow({ row, track, occupationId, occupationLabel, profileSignals, crossDomain }) {
  const courseId = firstString(row, [
    ['id'],
    ['education', 'id'],
    ['education', 'education_id'],
    ['education', 'educationId']
  ]);

  const courseTitle = firstString(row, [
    ['education_title'],
    ['education', 'title'],
    ['education', 'name'],
    ['education', 'education_title'],
    ['education', 'education_name'],
    ['education', 'headline'],
    ['education', 'label'],
    ['title'],
    ['name']
  ]);

  if (!courseTitle) {
    return null;
  }

  const provider = firstString(row, [
    ['education_provider_name'],
    ['providerSummary', 'providers', 0],
    ['providerSummary', 'name'],
    ['providerSummary', 'provider_name'],
    ['providerSummary', 'title'],
    ['education', 'provider_name'],
    ['education', 'provider']
  ]);

  const startDate = firstString(row, [
    ['eventSummary', 'executions', 0, 'start'],
    ['eventSummary', 'start_date'],
    ['eventSummary', 'startDate'],
    ['education', 'start_date'],
    ['education', 'startDate']
  ]);

  const duration = firstString(row, [
    ['eventSummary', 'duration'],
    ['eventSummary', 'duration_text'],
    ['eventSummary', 'durationText'],
    ['education', 'duration'],
    ['education', 'duration_text'],
    ['education', 'durationText'],
    ['education', 'pace_of_study_percentage']
  ]);

  const courseUrl = extractPublicCourseUrl(row);

  const reason = track === 'strengthen'
    ? `Relevant for ${occupationLabel} and aligned with your current profile direction.`
    : `Builds transferable skills toward ${occupationLabel} as a realistic pivot path.`;

  const confidence = scoreConfidence({
    track,
    startDate,
    duration,
    provider,
    crossDomain
  });

  const sourceSignals = profileSignals.slice(0, 5);

  return {
    track,
    occupationId,
    occupationLabel,
    courseTitle,
    provider: provider || null,
    startDate: startDate || null,
    duration: duration || null,
    courseId: courseId || null,
    courseUrl: courseUrl || null,
    confidence,
    reason,
    sourceSignals,
    _courseId: courseId || normalizedCourseKey(courseTitle, provider, occupationId),
    _startSort: toEpoch(startDate)
  };
}

function deriveSourceFieldIds({ explicitOccupationIds, inferredOccupationIds, taxonomy }) {
  const baseIds = explicitOccupationIds.length ? explicitOccupationIds : inferredOccupationIds;
  return new Set(
    baseIds
      .map((id) => taxonomy.occupationToField.get(id))
      .filter(Boolean)
  );
}

function mapOccupationFromJobTitlePayload(payload) {
  if (!payload || typeof payload !== 'object') {
    return { id: null, label: null };
  }

  const id = firstString(payload, [
    ['mapped_occupation_for_match', 'occupation_concept_id'],
    ['mapped_occupation_for_match', 'occupation_id']
  ]);

  const label = firstString(payload, [
    ['mapped_occupation_for_match', 'occupation_label']
  ]);

  return { id, label };
}

function dedupeAndRankTrack(items) {
  const byCourseId = new Map();
  for (const item of items) {
    if (!item?._courseId) continue;
    const existing = byCourseId.get(item._courseId);
    if (!existing) {
      byCourseId.set(item._courseId, item);
      continue;
    }
    if (item.confidence > existing.confidence) {
      byCourseId.set(item._courseId, item);
    }
  }

  const byVisibleKey = new Map();
  for (const item of byCourseId.values()) {
    const visibleKey = normalizedVisibleKey(item);
    const existing = byVisibleKey.get(visibleKey);
    if (!existing) {
      byVisibleKey.set(visibleKey, item);
      continue;
    }
    if (item.confidence > existing.confidence) {
      byVisibleKey.set(visibleKey, item);
    }
  }

  return Array.from(byVisibleKey.values()).sort((a, b) => {
    if (b.confidence !== a.confidence) return b.confidence - a.confidence;
    if (a._startSort !== b._startSort) return a._startSort - b._startSort;
    return a.courseTitle.localeCompare(b.courseTitle, 'sv');
  });
}

function stripInternalFields(item) {
  const { _courseId, _startSort, ...rest } = item;
  return rest;
}

async function enrichMissingCourseUrls(items) {
  if (!Array.isArray(items) || !items.length) return;

  const cache = new Map();
  for (const item of items) {
    if (!item || item.courseUrl) continue;
    const courseId = String(item._courseId || '').trim();
    if (!courseId || isSyntheticCourseId(courseId)) continue;

    let resolved = cache.get(courseId);
    if (resolved === undefined) {
      resolved = await fetchCourseUrlById(courseId);
      cache.set(courseId, resolved || null);
    }

    if (resolved) {
      item.courseUrl = resolved;
      if (!item.courseId) item.courseId = courseId;
    }
  }
}

async function fetchCourseUrlById(courseId) {
  try {
    const payload = await fetchJobEdConnect(`/v1/educations/${encodeURIComponent(courseId)}`, {
      method: 'GET'
    });
    return extractPublicCourseUrl(payload);
  } catch (error) {
    console.log('Education path: education-by-id link enrichment failed', {
      courseId,
      message: error.message
    });
    return null;
  }
}

function scoreConfidence({ track, startDate, duration, provider, crossDomain }) {
  let score = track === 'strengthen' ? 0.72 : 0.62;
  if (crossDomain) score += 0.05;
  if (provider) score += 0.03;
  if (duration) score += 0.03;

  const days = daysUntil(startDate);
  if (days !== null) {
    if (days <= 30) score += 0.1;
    else if (days <= 90) score += 0.06;
    else if (days <= 180) score += 0.03;
  } else {
    score -= 0.04;
  }

  return round2(clamp(score, 0, 0.98));
}

function daysUntil(value) {
  const date = parseDate(value);
  if (!date) return null;
  const diffMs = date.getTime() - Date.now();
  return Math.floor(diffMs / (1000 * 60 * 60 * 24));
}

function toEpoch(value) {
  const date = parseDate(value);
  return date ? date.getTime() : Number.MAX_SAFE_INTEGER;
}

function parseDate(value) {
  const raw = String(value || '').trim();
  if (!raw) return null;

  const direct = new Date(raw);
  if (!Number.isNaN(direct.getTime())) return direct;

  const m = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!m) return null;
  const [_, y, mm, d] = m;
  const date = new Date(Date.UTC(Number(y), Number(mm) - 1, Number(d)));
  return Number.isNaN(date.getTime()) ? null : date;
}

function firstString(source, pathOptions) {
  for (const path of pathOptions) {
    const value = getNested(source, path);
    if (typeof value === 'string' && value.trim()) {
      return value.trim();
    }
    if (typeof value === 'number' && Number.isFinite(value)) {
      return String(value);
    }
  }
  return null;
}

function getNested(source, path) {
  let current = source;
  for (const key of path) {
    if (!current || typeof current !== 'object') return null;
    current = current[key];
  }
  return current;
}

function normalizeSignals(profileSignals, explicitRoles, inferredRoles, inferredRoleDetails) {
  const detailSignals = inferredRoleDetails.flatMap((item) => {
    if (!item || typeof item !== 'object') return [];
    if (Array.isArray(item.sourceSignals)) return item.sourceSignals;
    if (typeof item.reason === 'string') return [item.reason];
    return [];
  });

  return uniqueStrings([
    ...(Array.isArray(profileSignals) ? profileSignals : []),
    ...explicitRoles,
    ...inferredRoles,
    ...detailSignals
  ]).slice(0, 12);
}

function buildSignalJobTitles(occupationLabel, profileSignals) {
  const candidates = uniqueStrings([occupationLabel, ...(Array.isArray(profileSignals) ? profileSignals : [])]);
  return candidates
    .filter((value) => {
      const words = value.split(/\s+/).filter(Boolean).length;
      return words >= 1 && words <= 6 && value.length <= 80;
    })
    .slice(0, 8);
}

function uniqueIds(values) {
  return uniqueStrings(values);
}

function uniqueStrings(values) {
  if (!Array.isArray(values)) return [];
  const seen = new Set();
  const result = [];
  for (const value of values) {
    const text = String(value || '').trim();
    if (!text) continue;
    const key = text.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(text);
  }
  return result;
}

function normalizedCourseKey(courseTitle, provider, occupationId) {
  return `${String(courseTitle || '').toLowerCase()}::${String(provider || '').toLowerCase()}::${String(occupationId || '').toLowerCase()}`;
}

function round2(value) {
  return Math.round(value * 100) / 100;
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function normalizedVisibleKey(item) {
  const title = normalizeKeyText(item?.courseTitle);
  const provider = normalizeKeyText(item?.provider);
  const startDate = normalizeDateKey(item?.startDate);
  const track = String(item?.track || '').trim().toLowerCase();
  return `${track}::${title}::${provider}::${startDate}`;
}

function normalizeKeyText(value) {
  const tokens = String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .split(/\s+/)
    .filter(Boolean);

  if (!tokens.length) return '';

  // Collapse duplicate consecutive tokens so tiny title formatting
  // differences do not create duplicate visible rows.
  const compacted = [];
  for (const token of tokens) {
    if (compacted[compacted.length - 1] === token) continue;
    compacted.push(token);
  }

  return compacted.join(' ');
}

function normalizeDateKey(value) {
  const date = parseDate(value);
  if (!date) return '';
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function extractPublicCourseUrl(source) {
  const direct = firstString(source, [
    ['application_url'],
    ['applicationUrl'],
    ['webpage_url'],
    ['webpageUrl'],
    ['education', 'application_url'],
    ['education', 'applicationUrl'],
    ['education', 'webpage_url'],
    ['education', 'webpageUrl'],
    ['education', 'url'],
    ['education', 'website'],
    ['education', 'homepage'],
    ['providerSummary', 'url'],
    ['providerSummary', 'website'],
    ['providerSummary', 'homepage'],
    ['providerSummary', 'apply_url'],
    ['providerSummary', 'applyUrl'],
    ['eventSummary', 'application_url'],
    ['eventSummary', 'applicationUrl'],
    ['eventSummary', 'webpage_url'],
    ['eventSummary', 'webpageUrl'],
    ['application_details', 'url'],
    ['application', 'url']
  ]);

  if (isLikelyPublicHttpUrl(direct)) {
    return direct;
  }

  return findPublicUrlHeuristic(source);
}

function findPublicUrlHeuristic(source) {
  if (!source || typeof source !== 'object') return null;

  const queue = [{ node: source, depth: 0 }];
  const seen = new Set();
  const MAX_DEPTH = 6;
  const MAX_NODES = 3000;
  let visited = 0;
  const candidates = [];

  while (queue.length && visited < MAX_NODES) {
    const { node, depth } = queue.shift();
    if (!node || typeof node !== 'object') continue;
    if (seen.has(node)) continue;
    seen.add(node);
    visited += 1;

    if (depth > MAX_DEPTH) continue;

    const entries = Array.isArray(node)
      ? node.map((value, index) => [String(index), value])
      : Object.entries(node);

    for (const [key, value] of entries) {
      if (typeof value === 'string' && isLikelyPublicHttpUrl(value)) {
        const score = urlKeyScore(key, value);
        candidates.push({ url: value, score });
        continue;
      }

      if (value && typeof value === 'object') {
        queue.push({ node: value, depth: depth + 1 });
      }
    }
  }

  if (!candidates.length) return null;
  candidates.sort((a, b) => b.score - a.score);
  return candidates[0].url;
}

function urlKeyScore(key, url) {
  const k = String(key || '').toLowerCase();
  let score = 0;

  if (/apply|application|ansok|ansokn|anmal/.test(k)) score += 50;
  if (/webpage|website|homepage|link|url/.test(k)) score += 25;
  if (isJobEdHostUrl(url)) score -= 40;
  if (isDocAssetUrl(url)) score -= 20;
  return score;
}

function isSyntheticCourseId(value) {
  return String(value || '').includes('::');
}

function isLikelyPublicHttpUrl(value) {
  const raw = String(value || '').trim();
  if (!raw) return false;
  if (!/^https?:\/\//i.test(raw)) return false;
  return true;
}

function isDocAssetUrl(url) {
  const raw = String(url || '').toLowerCase();
  return /\.(pdf|doc|docx|xls|xlsx|ppt|pptx)(\?|#|$)/.test(raw);
}

function isJobEdHostUrl(url) {
  const raw = String(url || '').toLowerCase();
  return raw.includes('jobed-connect-api.jobtechdev.se');
}

function tokenizeStemmed(value) {
  const normalized = String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
  if (!normalized) return [];

  const rawTokens = normalized.split(/\s+/).filter(Boolean);
  const compacted = [];
  for (const token of rawTokens) {
    const stem = stemToken(token);
    if (!stem) continue;
    if (compacted[compacted.length - 1] === stem) continue;
    compacted.push(stem);
  }
  return compacted;
}

function stemToken(token) {
  const t = String(token || '').trim();
  if (!t) return '';
  return t
    .replace(/(erna|ande|heten|elser|elserna|heten|arna|orna)$/u, '')
    .replace(/(ing|ion|are|er|or|en|et|ad|at|a|e)$/u, '')
    .trim();
}

function matchRatio(tokens, prefixes) {
  if (!Array.isArray(tokens) || !tokens.length) return 0;
  if (!Array.isArray(prefixes) || !prefixes.length) return 0;
  let matches = 0;
  for (const token of tokens) {
    if (prefixes.some((prefix) => token.startsWith(prefix))) {
      matches += 1;
    }
  }
  return matches / tokens.length;
}

module.exports = { resolveEducationPaths };
