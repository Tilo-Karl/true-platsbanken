function matchQueryOptions(profile, limit) {
  const options = {
    limit: Math.min(limit * 2, 500)
  };

  if (profile.municipality) {
    options.municipality = profile.municipality;
  }

  return options;
}

module.exports = { matchQueryOptions };
