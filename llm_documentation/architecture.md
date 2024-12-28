# Architecture

This document describes how Phoenix, LiveView, and GenServer integrate to power the “Click the Button” game.

## 1. Phoenix & LiveView

- **Phoenix Framework**: Handles HTTP requests and WebSocket connections.
- **LiveView**: Provides real-time, interactive views without manual JavaScript for updates.
  - When a user visits the site, a LiveView process is started for that user.
  - The LiveView process subscribes to relevant PubSub topics (e.g., “leaderboard_updates”) to receive real-time messages.

## 2. GenServer (Game Engine)

- **Core State Management**: A single GenServer holds the global game state. This includes:
  - A map of player UUIDs to their current scores.
  - A map of UUIDs to last-click timestamps (used for throttling and resetting scores).
- **ETS Storage**: The GenServer may use an ETS table to store and quickly retrieve player data:
  - ETS is fast for concurrent reads/writes.
  - The GenServer acts as the main coordinator for state modifications.

## 3. Data Flow

1. **User Click**: When a user clicks the button, a LiveView event is triggered.
2. **GenServer Call**: The LiveView sends a message to the GenServer with the user’s UUID.
3. **Business Logic**:
   - The GenServer checks throttle conditions (click frequency).
   - If allowed, it increments the user’s score in the ETS table.
   - It then broadcasts a “score updated” event via Phoenix PubSub.
4. **LiveView Update**: All subscribed LiveViews receive the “score updated” event. They fetch updated leaderboard data from the GenServer and re-render in real time.

## 4. Persistence

- **Periodic Save**: A separate process or a scheduled task within the GenServer can periodically dump ETS data to disk for durability. This should be done in a way that doesn't block the main GenServer process, and should just be a flatfile of some sort. No databases!
  - If there have been no clicks/state changes since the last write, then don't write to disk.
- **Load on Startup**: When the application starts, the GenServer loads previously saved data from disk and into ETS, ensuring continuity of scores.

## 5. Scaling & Clustering

- **Single Node** (initial):
  - Simple setup using ETS locally.
- **Multi-Node** (possible expansion):
  - Consider using Phoenix PubSub across nodes.
  - For truly shared state, migrate to Mnesia or a shared Postgres database.
  - Each node’s GenServer could coordinate with a central datastore or replicate the state.

This architecture leverages Phoenix LiveView for a dynamic UI and a GenServer for coordinated, in-memory game logic, ensuring real-time interactivity at scale.
