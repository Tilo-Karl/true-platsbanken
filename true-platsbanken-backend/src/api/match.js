const { normalizeMatchRequest } = require('../domain/matching/normalizeMatchRequest');
const { buildProfileSignalsFromProfile } = require('../domain/profile/profileSignalInput');
const { buildEmbeddingInputs, extractEmbeddings } = require('../domain/matching/embeddingText');
const { rankSemanticMatches } = require('../domain/matching/semanticMatch');
const { buildMatchJobPools } = require('../domain/matching/jobPool');
const { postOpenAI } = require('../readers/openai');

const JUNIOR_TITLE_MARKERS = [
  'junior',
  'trainee',
  'entry level',
  'praktik',
  'intern'
];
const MANUAL_HEAVY_MARKERS = [
  'terminalarbet',
  'lagerarbet',
  'truckförare',
  'montör',
  'operatör',
  'chaufför',
  'plock',
  'pack',
  'städ',
  'butiksmedarbet',
  'bud'
];
const LEADERSHIP_MARKERS = [
  'manager',
  'chef',
  'lead',
  'ansvarig',
  'samordnare',
  'projektledare',
  'driftledare',
  'produktionsledare'
];

async function getSemanticMatches(db, request) {
  const { profile, limit, profileEmbedding } = normalizeMatchRequest(request);
  if (!profile) {
    throw new Error('profile is required');
  }

  const profileSignals = buildProfileSignalsFromProfile(profile);

  const { corePool, pivotPool, opportunityProfile } = await buildMatchJobPools(profile, limit);
  const jobs = [...corePool, ...pivotPool];

  if (jobs.length === 0) {
    return {
      matches: [],
      coreMatches: [],
      pivotMatches: [],
      count: 0,
      coreCount: 0,
      pivotCount: 0,
      opportunityProfile
    };
  }

  const { profileText, jobTexts, inputs } = buildEmbeddingInputs(profileSignals, jobs);
  console.log('Match debug: profileTextLength', profileText.length, 'jobTextCount', jobTexts.length);
  if (!profileText.trim()) {
    throw new Error('profile text is required for embeddings');
  }

  let resolvedProfileEmbedding = profileEmbedding;
  let jobEmbeddings = [];

  if (Array.isArray(profileEmbedding) && profileEmbedding.length > 0) {
    console.log('Match debug: using cached profile embedding', profileEmbedding.length);
    const payload = await postOpenAI('/v1/embeddings', {
      model: 'text-embedding-3-small',
      input: jobTexts
    });
    jobEmbeddings = Array.isArray(payload?.data)
      ? payload.data.map(item => item.embedding)
      : [];
  } else {
    console.log('Match debug: embedding profile + jobs');
    const payload = await postOpenAI('/v1/embeddings', {
      model: 'text-embedding-3-small',
      input: inputs
    });
    const extracted = extractEmbeddings(payload);
    resolvedProfileEmbedding = extracted.profileEmbedding;
    jobEmbeddings = extracted.jobEmbeddings;
  }

  console.log('Match debug: embeddings', {
    profileEmbeddingLength: Array.isArray(resolvedProfileEmbedding) ? resolvedProfileEmbedding.length : 0,
    jobEmbeddingsCount: Array.isArray(jobEmbeddings) ? jobEmbeddings.length : 0
  });

  const allMatches = rankSemanticMatches(
    jobs,
    resolvedProfileEmbedding,
    jobEmbeddings,
    profileSignals,
    Math.max(limit * 2, limit + 10)
  );
  const adjustedMatches = adjustPivotRanking(allMatches, opportunityProfile);
  const coreMatches = adjustedMatches
    .filter((match) => match.matchType === 'core')
    .slice(0, limit);
  const pivotRanked = adjustedMatches
    .filter((match) => match.matchType === 'pivot');
  const pivotMatches = applyPivotFamilyCap(pivotRanked, limit);
  const matches = [...coreMatches, ...pivotMatches];
  const cleanedCoreMatches = stripInternalRankingFields(coreMatches);
  const cleanedPivotMatches = stripInternalRankingFields(pivotMatches);
  const cleanedMatches = stripInternalRankingFields(matches);

  console.log('Match debug: matches', cleanedMatches.length);
  return {
    matches: cleanedMatches,
    coreMatches: cleanedCoreMatches,
    pivotMatches: cleanedPivotMatches,
    count: cleanedMatches.length,
    coreCount: cleanedCoreMatches.length,
    pivotCount: cleanedPivotMatches.length,
    opportunityProfile
  };
}

function adjustPivotRanking(matches, opportunityProfile) {
  const stage = String(opportunityProfile?.careerStage || '').toLowerCase();
  const capabilities = Array.isArray(opportunityProfile?.transferableCapabilities)
    ? opportunityProfile.transferableCapabilities.map((value) => String(value).toLowerCase())
    : [];
  const familyMatchers = buildPivotFamilyMatchers(opportunityProfile);

  const adjusted = (Array.isArray(matches) ? matches : []).map((match) => {
    if (match.matchType !== 'pivot') {
      return { ...match, _rankScore: numericScore(match.score) };
    }

    const family = resolvePivotFamily(match, familyMatchers);
    const penalty = stagePenalty({
      job: match?.job,
      stage,
      capabilities
    });
    const base = numericScore(match.score);
    const familyBoost = family ? Math.min(0.08, Math.max(0, Number(family.fitScore || 0)) * 0.01) : 0;
    const adjustedScore = round4(base - penalty + familyBoost);

    return {
      ...match,
      score: adjustedScore,
      pivotFamily: family ? { id: family.id, label: family.label } : null,
      _rankScore: adjustedScore
    };
  });

  return adjusted.sort((a, b) => b._rankScore - a._rankScore);
}

function applyPivotFamilyCap(matches, limit) {
  const ranked = Array.isArray(matches) ? matches : [];
  if (!ranked.length || limit <= 0) return [];

  const familyBuckets = new Map();
  for (const match of ranked) {
    const familyId = String(match?.pivotFamily?.id || '').trim();
    const familyLabel = String(match?.pivotFamily?.label || '').trim();
    const familyKey = familyId || familyLabel || 'unmapped';
    const current = familyBuckets.get(familyKey);
    if (current) {
      current.push(match);
    } else {
      familyBuckets.set(familyKey, [match]);
    }
  }

  const families = Array.from(familyBuckets.values())
    .map((items) => {
      const sortedItems = [...items].sort((a, b) => numericScore(b?.score) - numericScore(a?.score));
      return {
        items: sortedItems,
        index: 0,
        headScore: numericScore(sortedItems[0]?.score)
      };
    })
    .sort((a, b) => b.headScore - a.headScore);

  const result = [];
  while (result.length < limit && families.length > 0) {
    let emittedInRound = 0;

    for (const family of families) {
      if (result.length >= limit) break;
      const nextMatch = family.items[family.index];
      if (!nextMatch) continue;
      result.push(nextMatch);
      family.index += 1;
      emittedInRound += 1;
    }

    for (let i = families.length - 1; i >= 0; i -= 1) {
      if (families[i].index >= families[i].items.length) {
        families.splice(i, 1);
      }
    }

    if (!emittedInRound) break;
  }

  return result;
}

function stagePenalty({ job, stage, capabilities }) {
  const text = normalizeText([
    job?.title,
    job?.occupationLabel,
    job?.occupationGroupLabel,
    job?.description
  ].filter(Boolean).join(' '));

  const juniorHit = containsAny(text, JUNIOR_TITLE_MARKERS);
  const manualHit = containsAny(text, MANUAL_HEAVY_MARKERS);
  const leadershipHit = containsAny(text, LEADERSHIP_MARKERS);
  const leadershipCapability = capabilities.includes('leadership');

  let penalty = 0;
  if (stage === 'advanced') {
    if (juniorHit) penalty += 0.2;
    if (manualHit) penalty += 0.24;
    if (leadershipHit) penalty -= 0.06;
  } else if (stage === 'mid') {
    if (juniorHit) penalty += 0.1;
    if (manualHit) penalty += 0.14;
    if (leadershipHit) penalty -= 0.03;
  } else {
    if (juniorHit) penalty += 0.04;
    if (manualHit) penalty += 0.06;
  }

  if (leadershipCapability && manualHit) {
    penalty += 0.05;
  }

  return Math.max(-0.08, Math.min(0.35, penalty));
}

function buildPivotFamilyMatchers(opportunityProfile) {
  const families = Array.isArray(opportunityProfile?.pivotOpportunityFamilies)
    ? opportunityProfile.pivotOpportunityFamilies
    : [];

  const mapped = families.map((family) => {
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

  return mapped;
}

function resolvePivotFamily(match, families) {
  const directFamily = normalizePivotFamily(match?.pivotFamily || match?.job?._pivotFamily);
  if (directFamily) {
    return directFamily;
  }
  return inferPivotFamily(match?.job, families);
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

function numericScore(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 0;
  return parsed;
}

function containsAny(text, needles) {
  if (!text || !Array.isArray(needles)) return false;
  return needles.some((needle) => text.includes(normalizeText(needle)));
}

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
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

function round4(value) {
  return Math.round(Number(value) * 10000) / 10000;
}

function stripInternalRankingFields(matches) {
  return (Array.isArray(matches) ? matches : []).map(({ _rankScore, ...rest }) => rest);
}

module.exports = { getSemanticMatches };
