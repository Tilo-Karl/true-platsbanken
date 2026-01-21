async function updateProfile(db, profileData) {
  if (!db) {
    throw new Error('Firestore db is required');
  }

  if (!profileData.userId) {
    throw new Error('userId is required');
  }

  if (!profileData.name || !profileData.email) {
    throw new Error('name and email are required');
  }

  const profileId = `profile_${profileData.userId}`;
  const now = new Date().toISOString();

  const profile = {
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

  const docRef = db.collection('profiles').doc(profileId);
  await docRef.set(profile, { merge: true });

  return { id: profileId, ...profile };
}

module.exports = { updateProfile };