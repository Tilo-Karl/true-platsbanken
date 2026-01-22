async function getProfileById(db, profileId) {
  const profileDoc = await db.collection('profiles').doc(profileId).get();
  if (!profileDoc.exists) {
    return null;
  }
  return profileDoc.data();
}

module.exports = { getProfileById };
