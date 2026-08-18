## 2024-05-24 - Synchronous localStorage reads cause UI blocking
**Learning:** The application's data layer (`db.js`) synchronously parses `localStorage` via `JSON.parse` on every read operation. This causes significant main thread blocking during frequent UI events, like typing in search fields.
**Action:** Always implement debouncing (e.g., using a custom `debounceUI` helper) on input events that trigger read operations to `db.js` to avoid degrading rendering performance and user experience.
