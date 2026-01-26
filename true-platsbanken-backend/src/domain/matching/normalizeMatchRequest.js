function normalizeMatchRequest(request = {}) {
  const rawLimit = Number(request.limit);
  const limit = Number.isFinite(rawLimit) && rawLimit > 0 ? rawLimit : 20;

  return {
    profileId: request.profileId,
    profile: request.profile,
    limit
  };
}

module.exports = { normalizeMatchRequest };
