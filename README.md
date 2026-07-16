# NairaBank

NairaBank is a responsive Nigerian retail-banking dashboard simulation built with React, TypeScript, Vite, Zustand, Recharts, and Phosphor Icons.

It is intentionally frontend-only. It demonstrates component architecture, asynchronous service behavior, domain modelling, loading and failure states, responsive financial data presentation, accessibility, tests, and production build discipline without presenting itself as a licensed bank.

## Features

- Available balance with privacy toggle
- Masked Nigerian account number
- Seven-day balance trend
- Quick action simulations
- Recent transaction history
- Spending category chart
- Daily and monthly transfer limits
- Desktop sidebar and mobile bottom navigation
- Shimmer loading and retryable errors

## Commands

    npm install
    npm run dev
    npm run lint
    npm run typecheck
    npm run test
    npm run build

## Simulation controls

- `?simulateError=true` forces a recoverable request failure.
- `?delay=2500` extends artificial latency.

## Vercel

Build command: `npm run build`
Output directory: `dist`

## Disclaimer

This is a portfolio demonstration. It does not authenticate users, store customer data, initiate transfers, or connect to financial infrastructure.
