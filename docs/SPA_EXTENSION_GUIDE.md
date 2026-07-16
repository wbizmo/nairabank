# SPA extension guide

## Adding a new view

1. Add the identifier to DashboardView.
2. Add its label and description to the navigation configuration.
3. Add the corresponding icon mapping.
4. Implement the feature view under src/features.
5. Add the view to ViewRouter.
6. Add navigation and rendering tests.

## State boundaries

Use the dashboard store for data that behaves like remote account data.

Use the navigation store only for view selection.

Use the session store only for the simulated session lifecycle.

Keep temporary form values inside their feature component unless multiple
unrelated components genuinely require them.

## Service boundaries

Feature components must not import dashboard.json directly.

All dashboard data must continue to pass through:

- HTTP client
- Dashboard service
- Dashboard store
- Dashboard hook
- Feature components

This preserves the ability to replace the JSON fixture with a real API without
rewriting presentation components.

## Avoiding premature architecture

Do not add Redux, React Router, a form framework, or a component system merely
because the application may need one later.

Introduce larger dependencies when the application demonstrates the
corresponding complexity, not in anticipation of hypothetical requirements.
