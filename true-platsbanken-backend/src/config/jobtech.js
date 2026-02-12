const JOBTECH_CONFIG = {
  BASE_URL: 'https://jobsearch.api.jobtechdev.se',
  SEARCH_PATH: '/search',
  COMPLETE_PATH: '/complete',
  DEFAULT_LIMIT: 100,
  MAX_LIMIT: 100,
  DEFAULT_HEADERS: {
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  }
};

module.exports = { JOBTECH_CONFIG };
