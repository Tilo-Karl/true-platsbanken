const { buildPivotFamilyMatchers, resolvePivotFamily } = require('./pivotFamilyResolver');
const { stagePenalty } = require('./pivotStagePenalty');

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

function numericScore(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 0;
  return parsed;
}

function round4(value) {
  return Math.round(Number(value) * 10000) / 10000;
}

module.exports = { adjustPivotRanking };
