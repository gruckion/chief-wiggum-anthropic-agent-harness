# Skills Research Plan for Marathon-Ralph Agent Harness

## Objective

Create a comprehensive `skills/` directory containing `SKILL.md` files for each technology in the better-t-stack ecosystem. These skill files will enable the marathon-ralph agent to build web, mobile, CLI, desktop apps, scripts, and automate browser tasks with accurate, up-to-date knowledge.

## Research Method

1. **Documentation Crawling**: Use Firecrawl MCP tools to fetch official documentation
2. **Key Extraction**: Extract setup instructions, configuration patterns, common gotchas, and compatibility notes
3. **Skill File Creation**: Write concise, actionable SKILL.md files optimized for agent consumption

## Output Format

Each `SKILL.md` file should follow this structure:

```markdown
# [Technology Name]

## Overview
Brief description and primary use case

## Quick Start
Minimal setup commands and configuration

## Core Concepts
Essential patterns and APIs

## Common Patterns
Frequently used code patterns with examples

## Configuration
Key configuration options and files

## Gotchas & Troubleshooting
Common pitfalls and their solutions

## Compatibility Notes
Integration notes with other stack components
```

---

## Priority Order

Technologies are ordered by frequency of use and dependency chain:

1. **P0 - Foundation**: Runtime, Database basics, ORM
2. **P1 - Core Stack**: Backend frameworks, API layer, Auth
3. **P2 - Frontend**: Web and Native frameworks
4. **P3 - Infrastructure**: DB Setup, Payments, Addons

---

## Category Research Plans

### 1. Web Frontend

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **TanStack Router** | https://tanstack.com/router/latest/docs/framework/react/overview | File-based routing, type-safe routes, loaders, search params |
| **React Router** | https://reactrouter.com/en/main | Route configuration, loaders, actions, nested routes |
| **TanStack Start** | https://tanstack.com/start/latest/docs/framework/react/overview | Full-stack setup, SSR, server functions, deployment |
| **Next.js** | https://nextjs.org/docs | App Router, Server Components, API routes, middleware |
| **Nuxt** | https://nuxt.com/docs | Auto-imports, server routes, modules, composables |
| **Svelte/SvelteKit** | https://svelte.dev/docs, https://kit.svelte.dev/docs | Runes, load functions, form actions, adapters |
| **Solid/SolidStart** | https://docs.solidjs.com/, https://start.solidjs.com/ | Signals, createResource, server functions |

**Priority**: Next.js (P1), TanStack Router (P1), TanStack Start (P2), others (P3)

---

### 2. Native Frontend (Expo)

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **Expo + Bare** | https://docs.expo.dev/ | Bare workflow setup, native modules, EAS Build |
| **Expo + NativeWind** | https://www.nativewind.dev/v4/overview | Tailwind for RN, className prop, theme config |
| **Expo + Unistyles** | https://reactnativeunistyles.vercel.app/ | Runtime theming, breakpoints, variants |

**Priority**: Expo core (P1), NativeWind (P2), Unistyles (P3)

---

### 3. Backend Frameworks

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **Hono** | https://hono.dev/docs | Middleware, routing, adapters, RPC mode |
| **Elysia** | https://elysiajs.com/introduction.html | Type inference, plugins, Eden Treaty |
| **Express** | https://expressjs.com/en/guide/routing.html | Middleware chain, error handling, best practices |
| **Fastify** | https://fastify.dev/docs/latest/ | Schema validation, plugins, hooks lifecycle |
| **Convex** | https://docs.convex.dev/ | Real-time, mutations, queries, actions |

**Priority**: Hono (P0), Elysia (P1), Fastify (P2), Express (P2), Convex (P2)

---

### 4. Runtime

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **Bun** | https://bun.sh/docs | Package manager, bundler, test runner, APIs |
| **Node.js** | https://nodejs.org/docs/latest/api/ | Core modules, ESM, performance tips |
| **Cloudflare Workers** | https://developers.cloudflare.com/workers/ | Wrangler, bindings, KV, D1, limits |

**Priority**: Bun (P0), Node.js (P0), Cloudflare Workers (P1)

---

### 5. API Layer

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **tRPC** | https://trpc.io/docs | Router setup, procedures, React Query integration |
| **oRPC** | https://orpc.unnoq.com/docs | Contract-first, OpenAPI generation, client setup |

**Priority**: tRPC (P0), oRPC (P1)

---

### 6. Database

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **SQLite** | https://www.sqlite.org/docs.html | Schema design, WAL mode, JSON support |
| **PostgreSQL** | https://www.postgresql.org/docs/current/ | Data types, indexes, JSON, full-text search |
| **MySQL** | https://dev.mysql.com/doc/ | InnoDB, indexes, replication basics |
| **MongoDB** | https://www.mongodb.com/docs/manual/ | Document design, indexes, aggregation |

**Priority**: SQLite (P0), PostgreSQL (P0), MongoDB (P2), MySQL (P3)

---

### 7. ORM

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **Drizzle** | https://orm.drizzle.team/docs/overview | Schema definition, queries, migrations, relations |
| **Prisma** | https://www.prisma.io/docs | Schema, client generation, migrations |
| **Mongoose** | https://mongoosejs.com/docs/guide.html | Schema, virtuals, middleware, population |

**Priority**: Drizzle (P0), Prisma (P1), Mongoose (P2)

---

### 8. Database Setup/Hosting

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **Turso** | https://docs.turso.tech/ | LibSQL, embedded replicas, connection URL |
| **Cloudflare D1** | https://developers.cloudflare.com/d1/ | Wrangler bindings, migrations, limits |
| **Neon Postgres** | https://neon.tech/docs | Serverless driver, branching, connection pooling |
| **Supabase** | https://supabase.com/docs | Auth, Realtime, Edge Functions, client setup |
| **PlanetScale** | https://planetscale.com/docs | Branching, safe migrations, Vitess |
| **Docker (DB)** | https://docs.docker.com/ | Compose files for Postgres, MySQL, MongoDB |

**Priority**: Turso (P1), Neon (P1), Supabase (P1), D1 (P2), PlanetScale (P2), Docker (P2)

---

### 9. Authentication

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **Better-Auth** | https://www.better-auth.com/docs | Session management, providers, database adapters |
| **Clerk** | https://clerk.com/docs | Components, middleware, organizations |

**Priority**: Better-Auth (P0), Clerk (P1)

---

### 10. Payments

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **Polar** | https://docs.polar.sh/ | Subscriptions, webhooks, SDK setup |

**Priority**: Polar (P2)

---

### 11. Addons & Tooling

| Technology | Documentation URL | Key Information to Extract |
|------------|-------------------|---------------------------|
| **PWA** | https://web.dev/progressive-web-apps/ | Manifest, service workers, offline support |
| **Tauri** | https://tauri.app/v1/guides/ | Desktop bundling, Rust commands, IPC |
| **Biome** | https://biomejs.dev/guides/getting-started/ | Linting, formatting, config |
| **Turborepo** | https://turbo.build/repo/docs | Monorepo setup, caching, pipelines |
| **WXT** | https://wxt.dev/ | Browser extension framework, content scripts |

**Priority**: Biome (P1), Turborepo (P1), Tauri (P2), PWA (P2), WXT (P3)

---

## Execution Checklist

### Phase 1: Foundation (P0)
- [ ] `skills/runtime/bun.md`
- [ ] `skills/runtime/nodejs.md`
- [ ] `skills/database/sqlite.md`
- [ ] `skills/database/postgresql.md`
- [ ] `skills/orm/drizzle.md`
- [ ] `skills/api/trpc.md`
- [ ] `skills/backend/hono.md`
- [ ] `skills/auth/better-auth.md`

### Phase 2: Core Stack (P1)
- [ ] `skills/runtime/cloudflare-workers.md`
- [ ] `skills/backend/elysia.md`
- [ ] `skills/orm/prisma.md`
- [ ] `skills/api/orpc.md`
- [ ] `skills/auth/clerk.md`
- [ ] `skills/web-frontend/nextjs.md`
- [ ] `skills/web-frontend/tanstack-router.md`
- [ ] `skills/native-frontend/expo.md`
- [ ] `skills/db-setup/turso.md`
- [ ] `skills/db-setup/neon.md`
- [ ] `skills/db-setup/supabase.md`
- [ ] `skills/addons/biome.md`
- [ ] `skills/addons/turborepo.md`

### Phase 3: Extended Stack (P2)
- [ ] `skills/backend/fastify.md`
- [ ] `skills/backend/express.md`
- [ ] `skills/backend/convex.md`
- [ ] `skills/orm/mongoose.md`
- [ ] `skills/database/mongodb.md`
- [ ] `skills/web-frontend/tanstack-start.md`
- [ ] `skills/native-frontend/nativewind.md`
- [ ] `skills/db-setup/cloudflare-d1.md`
- [ ] `skills/db-setup/planetscale.md`
- [ ] `skills/db-setup/docker.md`
- [ ] `skills/payments/polar.md`
- [ ] `skills/addons/tauri.md`
- [ ] `skills/addons/pwa.md`

### Phase 4: Complete Coverage (P3)
- [ ] `skills/database/mysql.md`
- [ ] `skills/web-frontend/react-router.md`
- [ ] `skills/web-frontend/nuxt.md`
- [ ] `skills/web-frontend/svelte.md`
- [ ] `skills/web-frontend/solid.md`
- [ ] `skills/native-frontend/unistyles.md`
- [ ] `skills/addons/wxt.md`

---

## Research Commands

For each technology, use the following Firecrawl pattern:

```
1. Map the documentation site to discover all pages:
   firecrawl_map(url: "<docs-url>")

2. Scrape key pages for content:
   firecrawl_scrape(url: "<specific-page>", formats: ["markdown"])

3. Extract structured information if needed:
   firecrawl_extract(urls: [...], prompt: "Extract setup steps, configuration options, and common patterns")
```

---

## Directory Structure

```
skills/
├── runtime/
│   ├── bun.md
│   ├── nodejs.md
│   └── cloudflare-workers.md
├── database/
│   ├── sqlite.md
│   ├── postgresql.md
│   ├── mysql.md
│   └── mongodb.md
├── orm/
│   ├── drizzle.md
│   ├── prisma.md
│   └── mongoose.md
├── backend/
│   ├── hono.md
│   ├── elysia.md
│   ├── express.md
│   ├── fastify.md
│   └── convex.md
├── api/
│   ├── trpc.md
│   └── orpc.md
├── auth/
│   ├── better-auth.md
│   └── clerk.md
├── db-setup/
│   ├── turso.md
│   ├── cloudflare-d1.md
│   ├── neon.md
│   ├── supabase.md
│   ├── planetscale.md
│   └── docker.md
├── web-frontend/
│   ├── tanstack-router.md
│   ├── react-router.md
│   ├── tanstack-start.md
│   ├── nextjs.md
│   ├── nuxt.md
│   ├── svelte.md
│   └── solid.md
├── native-frontend/
│   ├── expo.md
│   ├── nativewind.md
│   └── unistyles.md
├── payments/
│   └── polar.md
└── addons/
    ├── pwa.md
    ├── tauri.md
    ├── biome.md
    ├── turborepo.md
    └── wxt.md
```

---

## Success Criteria

Each SKILL.md file should:
1. Enable the agent to set up the technology from scratch
2. Provide copy-paste ready configuration snippets
3. Document integration patterns with other stack components
4. List common errors and their solutions
5. Be concise (target: 200-500 lines per file)
