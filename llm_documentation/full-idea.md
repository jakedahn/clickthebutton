# Full Idea (10,000 ft. View)

The “Click the Button” game is a simple yet addictive global click counter where anyone can:

1. **Enter a Handle** (e.g., “Player1”).
2. **Click a Button** that increments their personal score.
3. **View a Live Leaderboard** of the top 100 players worldwide.

It’s built in Elixir with Phoenix LiveView to give a real-time experience without needing heavy front-end frameworks. A GenServer maintains a shared state of scores, ensuring that each user’s click instantly updates everyone’s leaderboard.

Key characteristics:

- **Global Competition**: Everyone competes on a single scoreboard.
- **Minimal Barriers**: No sign-up required beyond entering a handle.
- **Real-Time Fun**: Scores update immediately, encouraging “just one more click.”
- **Scalable Design**: ETS for quick reads, potential to move to a clustered environment if the game goes viral.

Beyond the technical learning, the game offers an engaging way to experiment with concurrency, functional programming concepts in Elixir, and the interactive features of Phoenix LiveView.
