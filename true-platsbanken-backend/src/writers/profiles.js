async function saveProfile(db, profile) {
  const docRef = db.collection('profiles').doc(profile.id);
  await docRef.set(profile, { merge: true });
  return profile;
}

module.exports = { saveProfile };
