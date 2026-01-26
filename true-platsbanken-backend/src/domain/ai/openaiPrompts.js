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
  return [
    {
      role: 'system',
      content: 'Return ONLY JSON with keys: inferredRoles (array of strings) and rationale (object mapping role to short explanation). Exclude any roles already present in roles. Only realistic adjacent roles.'
    },
    { role: 'user', content: JSON.stringify(profileJson) }
  ];
}

module.exports = { buildProfileExtractionMessages, buildRoleExpansionMessages };
