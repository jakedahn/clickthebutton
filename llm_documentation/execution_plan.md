_**User**_

Please take a look at @app-flow.md @architecture.md @full-idea.md @PRD.md and @tech-stack.md

I am new to Elixir, and this is a fun learning project. I would like for you to be my elixir learning buddy / tutor.

Given all of this context, I need you to come up with a high-level execution gameplan that will instructively guide me in a step-by-step path of learning. I don't want you to be super step-by-step, but some thought on the progression of the app emphasizing different areas of learning would be nice.

---

_**Assistant**_

# “Click the Button” Execution Game Plan

Here’s a straightforward, semi-ordered plan you can follow as you build out your Elixir “Click the Button” game, focusing on the learning milestones along the way:

## 1. **Phoenix Foundations**

- Spin up a fresh Phoenix project.
- Test a trivial LiveView component (e.g., a counter) to ensure LiveView is working properly.

**Goal**: Learn the basics of Phoenix, routing, and LiveView’s syntax (assigns, events, etc.).

---

## 2. **Basic “Click to Increment” Flow**

- Add a LiveView with a “Click Me” button and a local state counter.
- Keep it ephemeral at first—no backend store.

**Goal**: Learn event handling in LiveView, how to update assigns, and the difference between stateful and stateless components.

---

## 3. **Introducing GenServer & ETS**

- Create a GenServer to store global data in memory (e.g., a map or an ETS table keyed by `user_id -> current_score`).
- Hook your LiveView click event to call into this GenServer.
- Explore reading/writing to ETS from inside the GenServer.

**Goal**: Get your first taste of concurrency in Elixir.

---

## 4. **Persistence & Cookies**

- Set up user handle + UUID cookies in your LiveView or in a plug. Ensure your app reliably reads/writes them.
- Add a “periodic save” mechanism to persist your ETS data to disk in the GenServer and reload on startup.

**Goal**: Learn how Phoenix handles session-level data via cookies or session plugs.

---

## 5. **Real-Time Leaderboard**

- Convert your single-user count into a leaderboard that everyone sees.
- Broadcast updates from the GenServer to all LiveViews when someone’s score changes.

**Goal**: Observe how LiveView re-renders subscriptions in real time, and learn about Phoenix PubSub.

---

## 6. **Throttling & Rate Limiting**

- Implement click frequency detection (e.g., throttle users hammering the button at 50+ clicks/sec).
- Let the GenServer handle the throttling logic.
- Provide feedback in LiveView (e.g., disabled button or a throttle message).

**Goal**: Practice concurrency control, pattern matching, and managing cross-process state updates.

---

## 7. **Inactivity Reset**

- Track last-click timestamps in your GenServer.
- Reset a user’s “active” score to 0 after 5 minutes of inactivity, but retain a historical “high score” if needed.

**Goal**: Get comfortable scheduling tasks using `:timer` or internal GenServer calls.

---

## 8. **Polish & Deployment**

- Style your pages with Tailwind (or any other setup you prefer in Phoenix).
- Host your app on Fly.io or Gigalixir. Get used to container-based deployments or OTP releases.

**Goal**: Solidify skills around real-world DevOps with Phoenix + Elixir.

---

## Final Note

Throughout these steps, tinker and iterate. You’ll gradually pick up Elixir’s pattern matching, immutability, concurrency workflows, and Phoenix/LiveView specifics. When done, you’ll have a strong end-to-end grasp of building a real-time, stateful Elixir/Phoenix app.

**Have fun!**
