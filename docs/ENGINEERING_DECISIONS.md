# Engineering decisions and trade-offs

## React and TypeScript

React suits independently evolving dashboard features. Strict TypeScript catches unsafe integration assumptions. The additional tooling is justified for a portfolio project intended to demonstrate maintainability.

## Vite instead of Next.js

The product has one static dashboard, no server rendering requirement, and no backend routes. A full-stack framework would add deployment and routing surface without product value.

## Zustand instead of Redux or Context

Shared state is limited to request lifecycle, active navigation, and balance privacy. Redux would add ceremony. A monolithic context would work but offers less precise subscriptions. Zustand is small and reversible.

## Recharts

The supplied design includes one donut chart. Recharts provides responsive SVG behavior, tooltips, and a mature React API. Handwritten SVG would reduce dependency weight but increase geometry and testing cost.

## Phosphor Icons

Phosphor offers mature typed React exports and consistent outline iconography that matches the supplied restrained banking design.

## Service layer

Components never call `fetch` directly. HTTP failures, cancellation, latency, and fixture location stay behind services. The indirection is small and materially lowers migration cost.

## No authentication

Fake authentication would imply security that does not exist. A production banking product would require server-side authorization, secure sessions, step-up verification, device risk controls, and audit trails.

## No router

The requested scope is one dashboard. Navigation state demonstrates layout behavior without pretending multiple screens exist.
