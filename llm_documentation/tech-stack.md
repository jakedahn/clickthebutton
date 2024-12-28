# Tech Stack

This document specifies the primary technologies and tools used to build and deploy the “Click the Button” game.

## 1. Back-End

- **Elixir**: Functional language running on the Erlang VM for high concurrency and scalability.
- **Phoenix Framework**: Handles HTTP requests, routing, and real-time features via channels.
- **GenServer**: Core game logic and state management (handles scoreboard data, click events, throttling).
- **ETS (Erlang Term Storage)**: In-memory data store for fast lookups/updates.

## 2. Front-End

- **Phoenix LiveView**:
  - Real-time UI updates without manual JavaScript.
  - Renders a dynamic leaderboard and score display.
- **Tailwind CSS**:
  - Utility-first CSS framework for rapid styling.
  - Allows for clean and modern UI components without heavy custom CSS.

## 3. Deployment

- **Fly.io**:
  - Simple, container-based hosting platform.
  - Supports clustering and Elixir deployments out of the box.
  - Allows scaling with minimal configuration.

## 4. Other Considerations

- **PubSub**:
  - Phoenix PubSub used under the hood for broadcasting messages to LiveView clients.
  - Enables real-time, multi-node communication if scaled out.
- **Mnesia** (Potential Future Enhancement):
  - Could be used for distributed, in-memory data across multiple nodes if needed.

Overall, this tech stack leverages Elixir’s concurrency model for high performance, Phoenix LiveView for real-time interactions, and Fly.io for quick, scalable deployment. The result is a lightweight, responsive application that can grow as user demand increases.
