# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Workspace for a technical test: a Rails 8.1 API (`backend/`, Ruby 3.4, PostgreSQL) and a React 19 + TypeScript SPA built with Vite (`frontend/`). Everything runs through `docker-compose.yml`; Ruby isn't installed on the host, so all Rails commands run inside the `backend` container.

| Service    | Host port | Notes |
|------------|-----------|-------|
| `frontend` | 5173      | Vite dev server, HMR with polling (needed for WSL bind mounts) |
| `backend`  | 3000      | Runs `bin/rails db:prepare` and then `rails server` on every start |
| `db`       | 5432      | Postgres 16, user/password `postgres`/`postgres`, data in the `pg_data` volume |

## Commands

```bash
docker compose up --build              # first run, or after changing Gemfile / package.json
docker compose up -d                   # day-to-day
docker compose down                    # stop (add -v to wipe the DB and the gem/node_modules volumes)

# Backend (Rails, Minitest)
docker compose exec backend bin/rails g scaffold Post title:string
docker compose exec backend bin/rails db:migrate
docker compose exec backend bin/rails test                                   # all tests
docker compose exec backend bin/rails test test/models/post_test.rb          # one file
docker compose exec backend bin/rails test test/models/post_test.rb:12       # one test by line
docker compose exec backend bin/rubocop                                      # lint (rubocop-rails-omakase)
docker compose exec backend bin/brakeman                                     # security scan
docker compose exec backend bin/rails console

# Frontend
docker compose exec frontend npm install <pkg>
docker compose exec frontend npm run lint     # oxlint
docker compose exec frontend npm run build    # tsc -b && vite build (type-check)
```

The frontend has no test runner configured yet.

`bin/new-backend` (repo root) is the bootstrap script that generated `backend/` (`rails new . --api --database=postgresql --skip-git --skip-kamal --skip-thruster`, plus `rack-cors`). It does nothing if `backend/Gemfile` already exists.

## Architecture / wiring

- **Frontend → backend calls**: use relative `/api/...` URLs. `frontend/vite.config.ts` proxies `/api` to `VITE_API_PROXY_TARGET` (`http://backend:3000` in compose), so no CORS is involved. Rails routes should go under `namespace :api` to match. Direct calls to `http://localhost:3000` also work, because `backend/config/initializers/cors.rb` allows `FRONTEND_ORIGIN` (default `http://localhost:5173`).
- **Host authorization**: `config.hosts << "backend"` in `backend/config/environments/development.rb` is required for the Vite proxy. Without it Rails returns 403 "Blocked hosts: backend:3000".
- **Database config**: the backend reads `DATABASE_URL` from `backend/.env` (gitignored), which points development at a hosted Supabase Postgres; compose does not set it. Tests use the local `db` service instead (`app_test`, via `config/database.yml`). The `db` service is only needed for tests. Starting the backend runs `db:prepare`, so pending migrations are applied to whatever database `DATABASE_URL` targets.
- **Authentication**: Clerk. The SPA signs users in with `@clerk/react` and sends the Clerk session token as `Authorization: Bearer ...` on `/api` calls. `backend/app/services/clerk.rb` verifies it against the instance JWKS, and `User.from_clerk` links (by email) or creates the local user on first sight. Env vars: `VITE_CLERK_PUBLISHABLE_KEY` in `frontend/.env.local`; `CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY` in `backend/.env` (both gitignored). Tests never call Clerk: a `test-<clerk_id>` bearer token authenticates that user (see `auth_headers` in `test_helper.rb`).
- **Dockerfiles**: development uses `backend/Dockerfile.dev` and `frontend/Dockerfile.dev`. `backend/Dockerfile` is Rails' generated production image and isn't used by compose.
- **Dependency volumes**: gems live in the `bundle` volume and `node_modules` in `frontend_node_modules`, not on the host bind mount. Install dependencies inside the containers or rebuild; a host `npm install` won't be seen by the container.
- The Rails app is API-only and uses the Rails 8 defaults Solid Cache, Solid Queue and Solid Cable. Only `GET /up` (health check) is routed so far.
