const { requireFirestoreDb } = require('../invariants/requireFirestoreDb');
const { requireProfileUpdateFields } = require('../invariants/requireProfileUpdateFields');
const { buildProfile } = require('../domain/profile/buildProfile');
const { saveProfile } = require('../writers/profiles');

async function updateProfile(db, profileData) {
  requireFirestoreDb(db);
  requireProfileUpdateFields(profileData);

  const now = new Date().toISOString();
  const profile = buildProfile(profileData, now);

  await saveProfile(db, profile);

  return profile;
}

module.exports = { updateProfile };
