# Product Requirements Document (PRD)

## 1. Overview

The “Click the Button” game is a real-time, browser-based experience where users click a button to increment their scores and compete on a global leaderboard.

## 2. Goals

- **Immediate Feedback**: Users see their updated scores and the leaderboard changes in real time.
- **Simplicity**: Eliminate unnecessary friction—just pick a handle and click.
- **Fair Play**: Basic throttling to prevent bots from dominating.

## 3. Features

1. **Handle Input**:
   - Prompt users to enter a handle on first visit.
   - Store handle + UUID in a cookie for subsequent visits.
2. **Global Leaderboard**:
   - Displays top 100 players by score.
   - Updates in real time across all connected clients.
3. **Increment Button**:
   - One button that increments the user’s score.
   - Score changes broadcast immediately.
4. **Rate Limiting**:
   - If a user surpasses 50 clicks/second, throttle them to 1 click/minute.
   - Provide a visual indicator or message for throttled users.
5. **Data Persistence**:
   - Player scores and handles should survive server restarts.
   - Periodic saves to disk.
6. **Scalability**:
   - Application should be able to run on a single node initially.
   - Optionally scale to multiple nodes with minimal code changes.

## 4. Success Metrics

- **Total Clicks**: Number of cumulative clicks globally.
- **Peak Concurrent Users**: How many users can be online clicking at once without performance degradation?
- **Retention**: How many players return to the site (cookie-based metric)?

## 5. Constraints & Assumptions

- **No Full Authentication**: A handle + UUID is enough; no passwords or login flows.
- **Minimal Front-End**: Rely on Phoenix LiveView for real-time updates.
- **High Availability** (Optional): If the game goes viral, consider multi-node setup with shared state.

## 6. Timeline

- **MVP**: Single-node deployment on Fly.io with in-memory ETS and periodic disk backup.
- **Production**: Add clustering and Postgres if required to handle higher load.

This PRD outlines the essential requirements and success criteria for launching and maintaining the “Click the Button” game.
