function requireProfileUpdateFields(profileData) {
  if (!profileData || typeof profileData !== 'object') {
    throw new Error('profile data is required');
  }
  if (!profileData.userId) {
    throw new Error('userId is required');
  }
  if (!profileData.name || !profileData.email) {
    throw new Error('name and email are required');
  }
  return profileData;
}

module.exports = { requireProfileUpdateFields };
