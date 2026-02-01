# Embedding Cache (Profile) — Why & How

## Goal
OpenAI embeddings are a per-call cost. Our matching flow generates embeddings every time the user taps Match. The profile text only changes when the user uploads a new CV, so the profile embedding can be cached to reduce repeated OpenAI calls.

This feature keeps the backend stateless while reducing embedding calls.

## What Changes
We add a small, client-side cache for **profile embeddings only**. Job embeddings are still generated on demand in the backend.

## Flow (End-to-End)
1. User uploads CV → profile extraction + role expansion run on backend.
2. Frontend calls **/api/embeddings** with the normalized profile payload.
3. Backend builds the profile embedding input text and returns **one embedding**.
4. Frontend stores the profile embedding in a local cache (UserDefaults) keyed by a hash of the CV text.
5. When the user taps Match:
   - If cached embedding exists, it is sent with the match request.
   - Backend reuses it and only embeds jobs.
   - If no cached embedding exists, backend embeds both profile + jobs as before.

## Why This Helps
- Saves OpenAI calls across repeated match attempts.
- No persistence in backend (still stateless).
- No API key on device (OpenAI key stays in backend).

## Clean Code Boundaries
- **Backend**
  - `readers/openai.js` remains the only OpenAI transport.
  - `/api/embeddings` is orchestration only.
  - Profile embedding text is built in domain logic.
- **Frontend**
  - ViewModels orchestrate only.
  - Cache is isolated in `EmbeddingCacheStore` (reader/writer).
  - Backend calls stay in readers (e.g., `BackendEmbeddingReader`).

## Files Added/Updated
Backend:
- `true-platsbanken-backend/src/api/embeddings.js`
- `true-platsbanken-backend/src/api/index.js`
- `true-platsbanken-backend/src/api/match.js`
- `true-platsbanken-backend/src/domain/matching/normalizeMatchRequest.js`

Frontend:
- `trueplatsbanken/trueplatsbanken/Services/BackendEmbeddingReader.swift`
- `trueplatsbanken/trueplatsbanken/Services/EmbeddingCacheStore.swift`
- `trueplatsbanken/trueplatsbanken/ViewModels/ProfileEditorViewModel.swift`
- `trueplatsbanken/trueplatsbanken/ViewModels/MatchResultsViewModel.swift`
- `trueplatsbanken/trueplatsbanken/Services/MatchReading.swift`
- `trueplatsbanken/trueplatsbanken/Services/BackendMatchReader.swift`
- `trueplatsbanken/trueplatsbanken/ViewModels/AppStateViewModel.swift`

## Notes
- Cache key = SHA256 hash of CV text.
- Cache version tag protects against future model changes.
- If cache read fails, matching still works (backend falls back to full embedding call).
