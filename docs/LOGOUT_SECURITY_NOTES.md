# Logout security notes

## Current implementation

The current logout feature is a local interaction model for the frontend
demonstration.

The confirmation step reduces accidental session termination and makes the
interaction explicit.

## Production requirements

A real banking logout operation should:

1. Revoke or rotate server-side credentials.
2. Invalidate refresh tokens.
3. Clear browser-held authentication material.
4. Terminate sensitive in-memory state.
5. Revalidate trusted-device state.
6. Write an auditable security event.
7. Redirect to a non-sensitive route.
8. Prevent protected data from being restored through browser history.
9. Consider logout propagation across multiple tabs.
10. Handle offline logout and delayed revocation safely.

## Why the demo does not fake these guarantees

Simulating token revocation solely in the browser would imply security behavior
that does not exist. The interface therefore states clearly that it terminates
only a local demonstration session.
