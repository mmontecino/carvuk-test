# carvuk

Rails (API) + React/Vite, todo en Docker.

## Proyecto deployado

Para el flujo de documentos SII (webhook) **usamos el proyecto deployado**, no un túnel local:

| Servicio | Plataforma | URL |
|---|---|---|
| Frontend (React/Vite) | Cloudflare Pages | https://carvuk-test.pages.dev |
| Backend (Rails API) | Render | https://carvuk-api-ll1h.onrender.com |
| Base de datos | Supabase (Postgres) | — |

El webhook del SII llega directo al backend en Render (`https://carvuk-api-ll1h.onrender.com/webhooks/sii`), por lo que
no se necesita ngrok. Ver [Deploy del backend](#deploy-del-backend-en-render) y
[Deploy del frontend](#deploy-del-frontend-en-cloudflare-pages). El desarrollo local (abajo) sigue disponible.

## Desarrollo local

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

## Documentos SII (webhook)

Al crear una boleta, el backend le pide al servicio externo (Pipedream, simula el SII) que emita el documento
con un `POST` a `https://eol9cyu9z953tcx.m.pipedream.net/document-sii`:

```json
{ "callbackUrl": "https://<url-publica>/webhooks/sii?token=...", "documentId": 1234 }
```

El SII responde después, de forma asíncrona, con un `POST` a esa `callbackUrl`
(`{ documentId, status, siiCode, pdfUrl }`). El resultado se guarda en la boleta y el historial
("Mis compras") muestra el **Número SII** y el **Link PDF**; mientras está pendiente se actualiza solo.

Para que el SII pueda llamar al webhook, `callbackUrl` debe ser una URL pública.

**Con el proyecto deployado (opción que usamos):** el backend en Render arma el `callbackUrl` solo con su URL
pública (`RENDER_EXTERNAL_URL`) y `SII_WEBHOOK_TOKEN` lo genera el Blueprint. No hay que configurar nada más.

**Alternativa, solo para correr el proyecto en local con ngrok:** expón el puerto 3000 del backend.

```bash
ngrok http 3000     # copia la URL https://xxxx.ngrok-free.app
```

y define estas variables en `backend/.env`, luego reinicia el backend (`docker compose restart backend`):

```
SII_CALLBACK_URL=https://xxxx.ngrok-free.app   # URL pública, sin /webhooks/sii
SII_WEBHOOK_TOKEN=<secreto aleatorio>          # ej.: openssl rand -hex 24
```

El token viaja en la `callbackUrl` y el webhook rechaza (401) cualquier llamada que no lo incluya.
`SII_ENDPOINT` permite cambiar el endpoint del SII (por defecto, el de Pipedream).

## Deploy del backend en Render

El repo incluye un [Blueprint](render.yaml) para desplegar la API (Rails) en Render con el `backend/Dockerfile`.
En producción se usa una sola base de datos (`DATABASE_URL`, p. ej. Supabase) y los jobs corren en el mismo proceso
(adaptador `async`), por lo que no hacen falta bases extra para cola, caché ni cable.

1. En Render: **New → Blueprint**, conecta este repo de GitHub y aplica `render.yaml`.
2. Completa las variables que pide (las marcadas como secretas no están en el repo):

   | Variable | Valor |
   |---|---|
   | `DATABASE_URL` | Cadena de conexión Postgres. En Supabase usa el *session pooler* (puerto 5432). |
   | `CLERK_PUBLISHABLE_KEY` / `CLERK_SECRET_KEY` | Las claves de tu aplicación en Clerk. |
   | `FRONTEND_ORIGIN` | URL(s) pública(s) del frontend, separadas por coma (CORS y validación del token de Clerk). |

   `SECRET_KEY_BASE` y `SII_WEBHOOK_TOKEN` se generan solos. No hace falta `SII_CALLBACK_URL`: en Render se usa
   automáticamente la URL pública del servicio (`RENDER_EXTERNAL_URL`) para el webhook del SII.
3. Al iniciar, el contenedor ejecuta `db:prepare` y aplica las migraciones pendientes.
4. Comprueba `https://<servicio>.onrender.com/up` (debe responder 200).

Notas:
- En el plan gratis el servicio se duerme tras ~15 min sin tráfico y la primera petición tarda cerca de un minuto;
  un webhook que llegue mientras duerme puede perderse.
- Con el adaptador `async`, los jobs pendientes se pierden al reiniciar el servicio.
- Si el frontend se sirve desde otro dominio, `/api` debe reenviarse al backend (rewrite/proxy) o el frontend debe
  llamar directamente a la URL de Render.

## Deploy del frontend en Cloudflare Pages

1. En Cloudflare: **Workers & Pages → Create → Pages → Connect to Git** y elige este repo.
2. Configuración de build:
   - **Root directory:** `frontend`
   - **Build command:** `npm run build`
   - **Build output directory:** `dist`
3. Variables de entorno del proyecto de Pages:

   | Variable | Valor |
   |---|---|
   | `VITE_CLERK_PUBLISHABLE_KEY` | La clave pública de Clerk (debe existir antes del build). |
   | `API_ORIGIN` | URL del backend en Render, p. ej. `https://carvuk-api.onrender.com`, sin `/` final. |

4. `frontend/functions/api/[[path]].ts` es una Pages Function que reenvía `/api/*` al backend (`API_ORIGIN`),
   igual que el proxy de Vite en desarrollo, así que el frontend sigue usando URLs relativas.
5. En el backend (Render) pon `FRONTEND_ORIGIN` con la URL de Pages (p. ej. `https://tu-app.pages.dev`, sin `/` final).
   También agrega ese dominio en Clerk si tu instancia lo exige.

El webhook del SII no pasa por Cloudflare: Pipedream llama directo a la URL de Render.
