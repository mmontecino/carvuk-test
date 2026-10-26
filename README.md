# carvuk

Rails (API) + React/Vite, todo en Docker.

| Servicio   | URL                      |
|------------|--------------------------|
| frontend   | http://localhost:5173    |
| backend    | http://localhost:3000    |
| postgres   | localhost:5432 (postgres/postgres) |

## Primera vez

```bash
bin/new-backend            # ejecuta `rails new --api -d postgresql` dentro de un contenedor ruby
docker compose up --build
```

## Día a día

```bash
docker compose up
docker compose exec backend bin/rails g scaffold Post title:string body:text
docker compose exec backend bin/rails db:migrate
docker compose exec backend bin/rails console
docker compose exec frontend npm install <paquete>
```

Desde React, las llamadas a `/api/...` se envían al backend a través del proxy de Vite
(sin problemas de CORS). Las llamadas directas a `http://localhost:3000` también están permitidas por `rack-cors`.
