const { buildRoleExpansionMessages } = require('../ai/openaiPrompts');

const ALLOWED_CATEGORIES = new Set([
  'Leadership & Delivery',
  'Operations & Coordination',
  'Product & Strategy',
  'Customer & Commercial',
  'Technical & Engineering',
  'Service & Support',
  'Field & Physical Operations'
]);
const DEFAULT_CATEGORY = 'Operations & Coordination';
const MAX_INFERRED_ROLES = 12;

function buildRoleExpansionPayload(profile, model = 'gpt-4o-mini') {
  return {
    model,
    temperature: 0,
    response_format: { type: 'json_object' },
    messages: buildRoleExpansionMessages(profile)
  };
}

function parseRoleExpansionResponse(payload) {
  const content = payload?.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('OpenAI chat response is empty');
  }

  return normalizeExpansion(JSON.parse(content));
}

function normalizeExpansion(value) {
  const rationale = normalizeRationale(value?.rationale);
  const normalizedItems = [
    ...normalizeInferredItems(value?.inferredRoles, rationale),
    ...normalizeInferredItems(value?.inferredRoleDetails, rationale)
  ];

  const inferredRoleDetails = uniqueByRole(normalizedItems).slice(0, MAX_INFERRED_ROLES);
  const inferredRoles = inferredRoleDetails.map(item => item.role);
  const normalizedRationale = buildRationale(rationale, inferredRoleDetails);

  return { inferredRoles, inferredRoleDetails, rationale: normalizedRationale };
}

function normalizeInferredItems(items, rationale) {
  if (!Array.isArray(items)) return [];

  const result = [];
  for (const item of items) {
    const role = extractRole(item);
    if (!role) continue;

    const reason = normalizeReason(extractReason(item, rationale, role));
    const sourceSignals = normalizeSignals(extractSignals(item), reason, role);

    result.push({
      role,
      category: normalizeCategory(extractCategory(item)),
      confidence: normalizeConfidence(extractConfidence(item)),
      reason,
      sourceSignals
    });
  }
  return result;
}

function extractRole(item) {
  if (typeof item === 'string') {
    const role = item.trim();
    return role || null;
  }
  if (item && typeof item === 'object') {
    const role = String(item.role || '').trim();
    return role || null;
  }
  return null;
}

function extractReason(item, rationale, role) {
  if (item && typeof item === 'object' && typeof item.reason === 'string') {
    return item.reason;
  }
  return rationale[role] || '';
}

function extractSignals(item) {
  if (!item || typeof item !== 'object') return [];
  return Array.isArray(item.sourceSignals) ? item.sourceSignals : [];
}

function extractCategory(item) {
  if (!item || typeof item !== 'object') return DEFAULT_CATEGORY;
  return typeof item.category === 'string' ? item.category : DEFAULT_CATEGORY;
}

function extractConfidence(item) {
  if (!item || typeof item !== 'object') return 0.6;
  return item.confidence;
}

function normalizeCategory(value) {
  const category = String(value || '').trim();
  if (ALLOWED_CATEGORIES.has(category)) {
    return category;
  }
  return DEFAULT_CATEGORY;
}

function normalizeConfidence(value) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) {
    return 0.6;
  }
  if (numeric > 1 && numeric <= 100) {
    return clampToTwoDecimals(numeric / 100);
  }
  return clampToTwoDecimals(Math.min(Math.max(numeric, 0), 1));
}

function clampToTwoDecimals(value) {
  return Math.round(value * 100) / 100;
}

function normalizeReason(value) {
  const reason = String(value || '').trim();
  return reason || 'Transferable evidence from prior work and skills.';
}

function normalizeSignals(signals, reason, role) {
  const normalized = uniquePreservingOrder(
    (Array.isArray(signals) ? signals : [])
      .map(signal => String(signal || '').trim())
      .filter(Boolean)
  ).slice(0, 6);

  if (normalized.length) {
    return normalized;
  }

  const reasonSignals = uniquePreservingOrder(
    String(reason)
      .split(/[,;]| and | samt /i)
      .map(part => part.trim())
      .filter(part => part.length >= 3)
  ).slice(0, 3);

  if (reasonSignals.length) {
    return reasonSignals;
  }

  return [role];
}

function normalizeRationale(value) {
  if (!value || typeof value !== 'object') return {};
  const result = {};
  for (const [key, reason] of Object.entries(value)) {
    const normalizedKey = String(key || '').trim();
    const normalizedReason = String(reason || '').trim();
    if (normalizedKey && normalizedReason) {
      result[normalizedKey] = normalizedReason;
    }
  }
  return result;
}

function buildRationale(baseRationale, inferredRoleDetails) {
  const result = { ...baseRationale };
  for (const item of inferredRoleDetails) {
    result[item.role] = item.reason;
  }
  return result;
}

function uniqueByRole(items) {
  const seen = new Set();
  const result = [];
  for (const item of items) {
    const key = String(item?.role || '').trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    result.push(item);
  }
  return result;
}

function uniquePreservingOrder(values) {
  const seen = new Set();
  const result = [];
  for (const value of values) {
    const key = String(value).trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    result.push(String(value).trim());
  }
  return result;
}

module.exports = { buildRoleExpansionPayload, parseRoleExpansionResponse };
