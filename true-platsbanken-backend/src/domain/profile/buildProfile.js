function buildProfile(profileData, now) {
  const profileId = `profile_${profileData.userId}`;

  return {
    id: profileId,
    userId: profileData.userId,
    name: String(profileData.name),
    email: String(profileData.email),
    phone: String(profileData.phone || ''),
    municipality: String(profileData.municipality || ''),
    employmentType: profileData.employmentType || 'any',
    skills: Array.isArray(profileData.skills) ? profileData.skills : [],
    cvText: String(profileData.cvText || ''),
    createdAt: profileData.createdAt || now,
    updatedAt: now
  };
}

module.exports = { buildProfile };
