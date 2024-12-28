# App Flow

This document outlines the user experience and flow of the “Click the Button” game at a high level.

## 1. Landing Page

- **User Enters Handle**: When a user visits `clickthebutton.lol`, they are prompted to enter a handle (e.g., “Alice”).
- **Cookie Setup**: Upon submission, a UUID is generated if the user doesn’t already have one in their cookie. The handle and UUID are saved to a cookie for future visits.

## 2. Game Screen

- **Leaderboard Sidebar**: Displays the top 100 players (sorted by score) on the left or right side of the page.
- **Current Score**: Shows the user’s current score (above the button) in a prominent location.
- **The Button**: A large button that, when clicked, increments the user’s score by 1.
- **Score Animation** (optional): On click, the user might see a quick animation or visual effect to confirm the score increment.
- **User Reset Cooldown**: The user's score is reset to 0 after 5 minutes of inactivity. They maintain their high watermark on the leaderboard, but they have to start from 0 and begin again.

## 3. Real-Time Updates

- **Live Leaderboard**: The leaderboard updates in real time as all connected users click the button.
- **User Score**: The user’s own score updates instantly on the screen.

## 4. Throttling / Rate Limiting

- **Bot Protection**: If the system detects more than 50 clicks in 1 second from a single user, that user is throttled to 1 click per minute until normal behavior resumes.

## 5. Returning Visitors

- **Cookie Check**: On subsequent visits, the user’s handle and UUID are loaded from cookies to restore their session automatically.
- **Score Retrieval**: The user’s existing score is retrieved from the persisted game data and displayed immediately.

## 6. Edge Cases

- **No Handle**: If a user visits with no handle in cookies and doesn’t enter one, they can’t play. (This flow can be refined as needed.)
- **Server Restarts**: If the server restarts, the data is reloaded from persistence, and existing scores remain intact.

This flow ensures a straightforward user experience—enter a handle, click the button, watch the leaderboard update in real time, and compete for the top spot!
