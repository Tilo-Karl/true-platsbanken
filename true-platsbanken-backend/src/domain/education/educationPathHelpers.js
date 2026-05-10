const { uniqueCaseInsensitiveStrings } = require('../shared/uniqueCaseInsensitiveStrings');

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
  return uniqueCaseInsensitiveStrings(values);
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

module.exports = {
  normalizeSignals,
  buildSignalJobTitles,
  uniqueIds,
  uniqueStrings,
  normalizedCourseKey,
  normalizedVisibleKey,
  scoreConfidence,
  toEpoch,
  parseDate,
  firstString,
  getNested,
  extractPublicCourseUrl,
  isSyntheticCourseId,
  tokenizeStemmed,
  matchRatio,
  round2,
  clamp
};
