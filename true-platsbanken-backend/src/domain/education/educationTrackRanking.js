const { normalizedVisibleKey } = require('./educationPathHelpers');

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

module.exports = { dedupeAndRankTrack, stripInternalFields };
