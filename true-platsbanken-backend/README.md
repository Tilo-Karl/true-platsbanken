# True Platsbanken Backend

Node.js + Firebase Functions backend for job matching application.

## Architecture

```
src/
├── index.js                 # Entry point: Express app + Firebase Functions
├── config/
│   ├── index.js
│   └── jobtech.js          # JobTech API constants
├── schemas/
│   ├── index.js
│   ├── job.schema.json
│   ├── profile.schema.json
│   └── match.schema.json
├── ingest/
│   ├── index.js            # Routes for /ingest/fetch
│   ├── fetchJobs.js        # Main ingestion logic
│   ├── normalizeJob.js     # API response → Job schema
│   └── jobStream.js        # Paging logic for JobTech API
├── api/
│   ├── index.js            # Route definitions
│   ├── jobs.js             # GET /api/jobs
│   ├── profile.js          # POST /api/profile
│   └── matches.js          # POST /api/matches
├── ai/
│   ├── index.js            # Placeholder
│   └── match/
│       ├── index.js
│       ├── jobVector.js    # Job representation
│       ├── score.js        # Profile-job scoring
│       └── bucket.js       # Score bucketing
└── scheduler/
    ├── index.js
    └── tick.js             # Programmable scheduler tick
```

## Setup

### Prerequisites
- Node.js 18+
- Firebase project with Firestore
- Firebase Admin SDK credentials (not committed to repo)

### Installation

```bash
npm install
```

### Environment

Set Firebase credentials via environment variables or use Application Default Credentials when deployed.

## API Endpoints

### Ingest
- `POST /ingest/fetch` - Fetch jobs from JobTech API and store in Firestore

### Jobs
- `GET /api/jobs?limit=50&cursor=publishedAt` - List jobs (newest first)

### Profile
- `POST /api/profile` - Create/update user profile

### Matches
- `POST /api/matches` - Get matched jobs for profile

### Scheduler
- `POST /scheduler/tick` - Manually trigger job ingestion

## Deployment

```bash
npm run deploy
```

This deploys Firebase Functions with automatic scheduling every 6 hours.

## JobTech API Integration

- Base URL: `https://jobsearch.api.jobtechdev.se/search`
- Default limit: 100 jobs per request
- Pagination: offset-based
- Response normalization: API → job.schema.json

## Data Flow

1. **Ingest (tick)**: JobTech API → normalizeJob → Firestore `jobs` collection
2. **API**: Firestore queries → response
3. **Matching**: Profile + jobs → scoring algorithm

## Notes

- Jobs are stored with JobTech job id as document id (idempotent)
- Profiles are stored as `profile_{userId}`
- Match scoring is deterministic and runs in-memory
- No local Firebase emulator required; uses real Firestore
