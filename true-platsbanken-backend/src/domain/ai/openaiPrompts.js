function buildProfileExtractionMessages(text) {
  return [
    {
      role: 'system',
      content: 'Return ONLY JSON with keys: keywords (array), roles (array), seniority (string or null), locations (array), summary (string). No extra keys.'
    },
    { role: 'user', content: text }
  ];
}

function buildRoleExpansionMessages(profileJson) {
  const categories = [
    'Leadership & Delivery',
    'Operations & Coordination',
    'Product & Strategy',
    'Customer & Commercial',
    'Technical & Engineering',
    'Service & Support',
    'Field & Physical Operations'
  ].join(', ');

  return [
    {
      role: 'system',
      content: [
        'Return ONLY JSON with keys: inferredRoles (array) and rationale (object).',
        'Each inferredRoles item must be an object with keys: role, category, confidence, reason, sourceSignals.',
        `category must be one of: ${categories}.`,
        'confidence must be a number from 0 to 1.',
        'sourceSignals must be a non-empty array of short evidence phrases from the profile.',
        'Focus on cross-domain employability from transferable skills, leadership, domain knowledge, tools/platform literacy, physical/operational work, customer/commercial work, coordination/planning, and technical literacy.',
        'Do NOT return roles that are explicit roles, close title synonyms, or simple renames of explicit roles.',
        'Return at most 8 inferred roles.'
      ].join(' ')
    },
    { role: 'user', content: JSON.stringify(profileJson) }
  ];
}

module.exports = { buildProfileExtractionMessages, buildRoleExpansionMessages };
