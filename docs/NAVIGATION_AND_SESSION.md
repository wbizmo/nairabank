# Navigation and session model

## Purpose

NairaBank is a frontend banking-dashboard demonstration. The navigation and
session implementation is designed to behave credibly without claiming that a
real banking authentication system exists.

## Navigation ownership

The navigation store owns one value: the active dashboard view.

Supported views are:

- Overview
- Cards
- Transfers
- Settings

The active view is persisted in localStorage. This provides continuity after a
browser refresh without introducing a router dependency for four internal
dashboard views.

## Why no external router

The application is a single dashboard surface with no public deep links,
authentication routes, nested layouts, or server-side rendering.

A dedicated router would become appropriate if the application later added:

- Public and authenticated route groups
- URL-addressable account or transaction details
- Browser history navigation requirements
- Route-level data loaders
- Code-split pages
- Protected routes

For the current scope, a typed view identifier and explicit view router keep
the application smaller and easier to understand.

## Session simulation

The session store supports:

- Requesting logout
- Cancelling logout
- Confirming logout
- Restoring the demonstration session

The signed-out state is persisted in sessionStorage rather than localStorage.
Closing the browser session therefore resets the demonstration naturally.

## Security boundary

The current logout button does not:

- Revoke an access token
- Invalidate refresh tokens
- Contact a backend
- Destroy a server-side session
- Clear real financial information
- Perform device revocation

A production implementation must treat logout as a server-coordinated security
operation and must not rely on client-side state alone.

## Accessibility

The navigation exposes the active destination through aria-current.

The logout dialog includes:

- Dialog semantics
- Modal state
- Accessible title and description associations
- Explicit cancel and confirmation actions
- Keyboard-visible focus states

A production implementation should additionally include focus trapping and
restoration through a tested dialog primitive.
