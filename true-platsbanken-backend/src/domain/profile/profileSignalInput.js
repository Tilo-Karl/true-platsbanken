const { extractProfileSignals } = require('./extractProfileSignals');

function buildProfileSignalsFromProfile(profile) {
  const skillsText = Array.isArray(profile.skills) ? profile.skills.join(', ') : '';
  const employmentPreferences = {
    employmentType: profile.employmentType,
    municipality: profile.municipality
  };

  return extractProfileSignals(
    skillsText,
    profile.cvText || '',
    employmentPreferences
  );
}

module.exports = { buildProfileSignalsFromProfile };
