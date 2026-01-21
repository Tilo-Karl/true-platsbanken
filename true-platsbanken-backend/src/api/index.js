const express = require('express');
const { listJobs } = require('./jobs');
const { updateProfile } = require('./profile');
const { getMatches } = require('./matches');

function apiRoutes(db) {
  const router = express.Router();

  router.get('/jobs', async (req, res) => {
    try {
      const result = await listJobs(db, req.query);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  router.post('/profile', async (req, res) => {
    try {
      const result = await updateProfile(db, req.body);
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  router.post('/matches', async (req, res) => {
    try {
      const result = await getMatches(db, req.body);
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  return router;
}

module.exports = { apiRoutes };