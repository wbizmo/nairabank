# Architecture

## Objective

Behave like a small production frontend while remaining honest about frontend-only scope. Remote-like state, domain contracts, transport mechanics, shared UI state, feature presentation, and deterministic utilities are separated so a real backend can replace the fixture without restructuring the interface.

## Module boundaries

- `domain`: stable account, transaction, and spending contracts
- `services`: HTTP behavior, latency, cancellation, and failure injection
- `store`: request lifecycle and small shared UI state
- `hooks`: React lifecycle integration
- `components/layout`: shell and responsive navigation
- `components/dashboard`: financial presentation
- `components/feedback`: loading, error, and transient messages
- `utils`: deterministic formatting and progress calculations
- `public/dashboard.json`: replaceable development API fixture

## Data flow

1. `useDashboard` requests data when the store is idle.
2. The store cancels any prior request and enters loading.
3. `dashboardService` applies controllable latency and calls `httpClient`.
4. Success is committed atomically, preventing partial dashboard renders.
5. Failures become explicit recoverable state.
6. Components consume typed values without transport knowledge.

## JSON fixture decision

Fetching JSON preserves a genuine asynchronous browser boundary. Importing a constant would hide request behavior and couple the dataset to the JavaScript bundle.

## Cancellation

A new request aborts the previous one, protecting the store from stale responses during retries and React Strict Mode remount behavior.

## Runtime behaviour

Dashboard data is loaded through the service boundary rather than imported directly into presentation components. The simulated request includes latency, cancellation support, recoverable failure handling, and explicit loading states. This keeps the current frontend demonstration structurally compatible with a future HTTP API.
