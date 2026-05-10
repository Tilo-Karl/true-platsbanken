function selectPivotMatches(matches, limit) {
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
  const selectedJobIds = new Set();
  while (result.length < limit && families.length > 0) {
    let emittedInRound = 0;

    for (const family of families) {
      if (result.length >= limit) break;
      let nextMatch = null;
      while (family.index < family.items.length) {
        const candidate = family.items[family.index];
        family.index += 1;
        if (!candidate || !candidate.job?.id) continue;
        if (selectedJobIds.has(candidate.job.id)) continue;
        nextMatch = candidate;
        break;
      }
      if (!nextMatch) continue;
      result.push(nextMatch);
      selectedJobIds.add(nextMatch.job.id);
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

function numericScore(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 0;
  return parsed;
}

module.exports = { selectPivotMatches };
