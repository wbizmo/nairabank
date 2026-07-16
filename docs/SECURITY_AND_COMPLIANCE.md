# Security and compliance boundary

NairaBank is a frontend simulation, not a regulated financial system.

A production implementation would require:

- authenticated, authorized server APIs
- encrypted transport and secure session handling
- server-side balance and limit enforcement
- transaction idempotency and replay protection
- step-up verification for sensitive actions
- fraud, velocity, and beneficiary controls
- privacy-safe telemetry and immutable audit logs
- PCI DSS scoping where card data is involved
- NDPR and applicable CBN requirements
- formal threat modelling and penetration testing

No decision made in this browser should be trusted by a real financial backend.
