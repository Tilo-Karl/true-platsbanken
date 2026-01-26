const express = require('express');
const { listJobs } = require('./jobs');
const { updateProfile } = require('./profile');
const { extractProfile } = require('./profileExtract');
const { expandProfileRoles } = require('./expandRoles');
const { getMatches } = require('./matches');
const { getSemanticMatches } = require('./match');

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
      if (req.body && typeof req.body.text === 'string') {
        const result = await extractProfile(req.body.text);
        res.status(200).json(result);
      } else {
        const result = await updateProfile(db, req.body);
        res.status(200).json(result);
      }
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  router.post('/profile/extract', async (req, res) => {
    try {
      const result = await extractProfile(req.body?.text);
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  router.post('/profile/expand-roles', async (req, res) => {
    try {
      const result = await expandProfileRoles(req.body);
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

  router.post('/match', async (req, res) => {
    try {
      const result = await getSemanticMatches(db, req.body);
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  return router;
}

module.exports = { apiRoutes };
