# Failure modes and recovery

## Dashboard request failure

The store enters `error`, retains a human-readable message, and exposes retry. It never invents partial balances.

## Superseded request

The previous AbortController is cancelled. Abort errors are ignored because they are expected lifecycle behavior.

## Runtime JSON drift

TypeScript protects compile-time consumers but not remote payloads. A real API should add runtime schema validation with Zod, Valibot, or generated contracts.

## Invalid limits

Percentage calculations guard against zero and negative limits and clamp output to zero through one hundred.

## Slow network

Skeletons preserve final geometry and reduce layout shift. The delay query parameter supports manual inspection.

## Chart failure

The chart is supplementary. Critical transaction and limit values remain available as text.
