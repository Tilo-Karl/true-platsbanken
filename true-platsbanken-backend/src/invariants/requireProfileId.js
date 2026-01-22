function requireProfileId(profileId) {
  if (!profileId) {
    throw new Error('profileId is required');
  }
  return profileId;
}

module.exports = { requireProfileId };
