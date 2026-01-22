function requireProfileExists(profile) {
  if (!profile) {
    throw new Error('Profile not found');
  }
  return profile;
}

module.exports = { requireProfileExists };
