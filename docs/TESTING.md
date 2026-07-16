# Testing strategy

## Automated

- formatter and percentage unit tests
- initial loading-state test
- successful account-load integration test
- simulated action feedback test
- strict type checking
- ESLint with zero warnings
- production Vite build

## Manual

- desktop sidebar and mobile bottom navigation
- balance hide/show interaction
- `?delay=2500` loading behavior
- `?simulateError=true` retry behavior
- responsive widths at 320, 390, 560, 860, 1024, and wide desktop
- reduced-motion operating-system preference
- Vercel production deployment
