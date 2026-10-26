# Carvuk — Tienda con boletas y documentos SII

Tienda en línea: el usuario inicia sesión, arma un carrito, compra y revisa sus boletas. Al comprar, el backend
solicita la emisión de un documento al **SII** (simulado con Pipedream) y recibe el resultado de forma asíncrona
mediante un **webhook**; el historial de boletas muestra el **número SII** y el **PDF** cuando están listos.

**Stack:** Rails 8.1 (API, Ruby 3.4) · PostgreSQL · React 19 + TypeScript + Vite · Clerk (autenticación) · Docker.

## Demo

| Servicio | Plataforma | URL |
|---|---|---|
| Frontend | Cloudflare Pages | https://carvuk-test.pages.dev |
| Backend (API) | Render | https://carvuk-api-ll1h.onrender.com |
| Base de datos | Supabase (Postgres) | — |
| Autenticación | Clerk (instancia de desarrollo) | — |

**Todos los servicios usan su capa gratuita** (Cloudflare Pages, Render, Supabase y Clerk; el SII es el simulador
gratuito de Pipedream). Es suficiente para esta prueba, pero implica limitaciones propias de ese tipo de planes; ver
las notas más abajo.

**Cómo probarlo**

1. Entra a https://carvuk-test.pages.dev y crea una cuenta (Clerk) desde **Iniciar sesión → Crear cuenta**.
2. Agrega productos al carrito y pulsa **Finalizar compra**.
3. Abre **Mis boletas**: la boleta aparece como *Generando…* y, en unos segundos, se completa sola con el
   **Número SII** y el enlace **Descargar boleta** (la página se actualiza cada 1 s mientras hay documentos pendientes).

> **Notas sobre la demo (capa gratuita)**
> - **Render (plan gratis):** el backend se duerme tras ~15 min sin uso y la primera petición puede tardar cerca de
>   un minuto en responder. Si abres la demo y no carga, espera y recarga.
> - **Supabase (plan gratis):** los proyectos sin actividad durante una semana se pausan; si ocurriera, la API
>   devolverá errores hasta reactivar el proyecto desde su dashboard.
> - **Clerk:** se usa una instancia de *desarrollo* (claves `pk_test_…`), pensada para pruebas y no para producción.
> - **Cloudflare Pages:** el plan gratis no tiene limitaciones relevantes para esta demo.
> - El número SII es siempre `SII-123456`: lo devuelve así el simulador de Pipedream (el backend guarda tal cual lo
>   que recibe en el webhook). Lo que cambia por boleta es el `documentId`.

## Funcionalidades

- **Autenticación con Clerk** (registro, login, sesión). La API valida el token de Clerk en cada petición.
- **Catálogo de productos** público.
- **Carrito** en el cliente, guardado por usuario (sobrevive a recargas y a cerrar sesión).
- **Compra → boleta**: el servidor recalcula todo (precios, neto, IVA y total); el cliente solo envía
  `{ product_id, amount }`.
- **Historial de boletas** por usuario, con detalle de ítems, totales, número SII y PDF.
- **Integración con el SII** vía job asíncrono + webhook.

## Arquitectura

```
Navegador ──► Cloudflare Pages (React SPA)
                   │  /api/*  (Pages Function = proxy)
                   ▼
              Render: Rails API ◄──────────── POST /webhooks/sii ───────────── Pipedream (simula el SII)
                   │      │                                                          ▲
                   │      └── SiiDocumentJob ── POST { callbackUrl, documentId } ───┘
                   ▼
              Supabase (Postgres)
```

Flujo de una compra:

1. `POST /api/receipts` crea la boleta (`sii_status = pending`) y, tras el commit, encola `SiiDocumentJob`.
2. El job hace `POST` al SII con `{ callbackUrl, documentId }`, donde `documentId` es el id de la boleta y
   `callbackUrl` es `https://<api>/webhooks/sii?token=<secreto>`. Reintenta hasta 5 veces y, si agota los intentos,
   marca la boleta como `failed`.
3. El SII responde después a la `callbackUrl` con `{ documentId, status, siiCode, pdfUrl }`.
4. `POST /webhooks/sii` valida el token, busca la boleta por `documentId` y guarda `sii_status`, `sii_code` y `pdf_url`.
5. El frontend consulta las boletas cada 1 s mientras alguna siga pendiente.

## Decisiones técnicas

- **Clerk con verificación propia del JWT.** El frontend envía el token de sesión como `Authorization: Bearer`; el
  backend lo verifica (RS256) contra las claves públicas (JWKS) de la instancia, validando emisor y origen
  autorizado (`azp`). No hay sesiones ni contraseñas en la API. Se reemplazó Devise/devise-jwt de la primera entrega.
- **Precios y totales siempre en el servidor.** Los precios incluyen IVA (`TAX_RATE`, por defecto 15 %):
  `neto = total / (1 + tasa)` y `IVA = total − neto`. Cada ítem guarda el `unit_price` pagado, así que cambiar el
  precio de un producto después no altera boletas antiguas.
- **Webhook protegido por token.** El SII no firma sus llamadas y el webhook no tiene sesión de usuario, así que la
  `callbackUrl` lleva un token secreto compartido; sin él, la respuesta es `401`. Solo se aceptan estados
  conocidos y enlaces PDF `http(s)`.
- **Proceso asíncrono.** La compra no espera al SII: responde de inmediato y el resultado llega por webhook.
- **Producción simplificada.** Una sola base de datos, caché en memoria y jobs en el mismo proceso (`async`), en vez
  de las bases extra de Solid Queue/Cache/Cable.

## API

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/up` | — | Health check |
| GET | `/api/products` | — | Catálogo |
| GET | `/api/receipts` | Clerk | Boletas del usuario (más recientes primero) |
| GET | `/api/receipts/:id` | Clerk | Detalle de una boleta propia |
| POST | `/api/receipts` | Clerk | Crea la boleta: `{ "receipt": { "items": [{ "product_id": 1, "amount": 2 }] } }` |
| POST | `/webhooks/sii?token=…` | Token | Resultado del SII: `{ documentId, status, siiCode, pdfUrl }` |

Una boleta incluye `sii_status` (`pending` · `issued` · `rejected` · `failed`), `sii_code` y `pdf_url`.

## Correr en local

**Requisitos:** Docker y Docker Compose (no hace falta Ruby, Node ni Postgres instalados) y una cuenta gratuita de
[Clerk](https://dashboard.clerk.com), que provee la autenticación. Los puertos `3000`, `5173` y `5432` deben estar libres.

**1. Clonar el repositorio**

```bash
git clone https://github.com/mmontecino/carvuk-test.git
cd carvuk-test
```

**2. Crear una aplicación en Clerk** (2 minutos)

En https://dashboard.clerk.com → *Create application* → habilita **Email** como método de acceso → en
**API keys** copia la *Publishable key* (`pk_test_…`) y la *Secret key* (`sk_test_…`).

**3. Configurar las variables de entorno**

```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env.local
```

- En `backend/.env`: pega `CLERK_PUBLISHABLE_KEY` y `CLERK_SECRET_KEY`. El resto de los valores ya sirve en local.
- En `frontend/.env.local`: pega la misma *Publishable key* en `VITE_CLERK_PUBLISHABLE_KEY`.

**4. Levantar todo**

```bash
docker compose up --build
```

La primera vez tarda unos minutos (construye las imágenes). El backend crea la base de datos y aplica las
migraciones y carga el catálogo de 13 productos (`db/seeds.rb`) solo la primera vez. Espera a ver
`Listening on http://0.0.0.0:3000`.

**5. Usar la aplicación**

| Servicio | URL |
|---|---|
| Frontend | http://localhost:5173 |
| Backend | http://localhost:3000 (health check: `/up`) |
| Postgres | localhost:5432 (`postgres` / `postgres`) |

Entra a http://localhost:5173, crea una cuenta, agrega productos al carrito y pulsa **Finalizar compra**. Tu boleta
aparece en **Mis boletas**.

**6. Documento del SII en local**

El SII (Pipedream) solo puede llamar a una URL pública, así que en local la boleta se crea con normalidad y queda en
*Generando…* (`pending`). El flujo real con el SII se ve en la [demo desplegada](#demo). Para completar una boleta
local, simula la respuesta del SII llamando al webhook (usa el `SII_WEBHOOK_TOKEN` de tu `backend/.env`, por defecto
`change-me`, y el id de la boleta en `documentId`):

```bash
curl -X POST "http://localhost:3000/webhooks/sii?token=change-me" \
  -H "Content-Type: application/json" \
  -d '{"documentId": 1, "status": "issued", "siiCode": "SII-123456", "pdfUrl": "https://example.com/boleta.pdf"}'
```

La página de boletas se actualiza sola y muestra el número SII y el enlace de descarga.

**Comandos útiles**

```bash
docker compose down            # detener
docker compose down -v         # detener y borrar la base de datos local
docker compose logs -f backend # ver los logs de la API
```

## Tests y calidad

```bash
docker compose exec backend bin/rails db:test:prepare test   # 71 tests (modelos, controladores, webhook, job, tokens, cliente SII)
docker compose exec backend bin/rubocop          # estilo (rubocop-rails-omakase)
docker compose exec backend bin/brakeman         # análisis de seguridad
docker compose exec frontend npm run lint        # oxlint
docker compose exec frontend npm run build       # type-check (tsc) + build
```

`db:test:prepare` crea la base de test la primera vez (los tests usan siempre el Postgres local, nunca `DATABASE_URL`).
Los tests no llaman a Clerk ni al SII: un token `test-<clerk_id>` autentica a ese usuario y el cliente del SII se
reemplaza en el test del job. El frontend aún no tiene tests automatizados.

## Variables de entorno

| Variable | Dónde | Descripción |
|---|---|---|
| `DATABASE_URL` | backend | Conexión a Postgres |
| `TAX_RATE` | backend | Tasa de IVA incluida en los precios (default `0.15`) |
| `CLERK_PUBLISHABLE_KEY` | backend | Clave pública de Clerk (de ahí se deriva el emisor del JWT) |
| `CLERK_SECRET_KEY` | backend | Clave secreta de Clerk (consulta de usuarios en su API) |
| `FRONTEND_ORIGIN` | backend | Origen(es) del frontend, separados por coma (CORS y validación `azp`) |
| `SII_WEBHOOK_TOKEN` | backend | Secreto del webhook del SII |
| `SII_CALLBACK_URL` | backend | URL pública de la API; en Render se toma de `RENDER_EXTERNAL_URL` |
| `SII_ENDPOINT` | backend | Endpoint del SII (default: el de Pipedream) |
| `SECRET_KEY_BASE` | backend (prod) | Secreto de Rails en producción |
| `VITE_CLERK_PUBLISHABLE_KEY` | frontend | Clave pública de Clerk |
| `API_ORIGIN` | Cloudflare Pages | URL del backend a la que la Pages Function reenvía `/api/*` |

## Deploy

**Backend en Render.** El [Blueprint](render.yaml) despliega `backend/Dockerfile` (Docker, plan gratis, región Ohio).
En Render: *New → Blueprint*, elige este repo y completa `DATABASE_URL` (en Supabase, el *session pooler*, puerto
5432), `CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY` y `FRONTEND_ORIGIN`. `SECRET_KEY_BASE` y `SII_WEBHOOK_TOKEN` se
generan solos y el `callbackUrl` usa `RENDER_EXTERNAL_URL`. Al iniciar, el contenedor ejecuta `db:prepare`
(aplica migraciones). Comprueba `/up`.

**Frontend en Cloudflare Pages.** *Workers & Pages → Create → Pages → Connect to Git*:

- Root directory: `frontend` · Build command: `npm run build` · Output directory: `dist`
- Variables: `VITE_CLERK_PUBLISHABLE_KEY` (antes del build) y `API_ORIGIN` (URL de Render, sin `/` final).

[`frontend/functions/api/[[path]].ts`](frontend/functions/api/[[path]].ts) es una Pages Function que reenvía
`/api/*` al backend, igual que el proxy de Vite en desarrollo. El webhook del SII **no** pasa por Cloudflare: llega
directo a Render.

## Limitaciones y mejoras posibles

- **Jobs en memoria** (`async`): si Render reinicia o duerme el servicio justo después de una compra, la solicitud al
  SII se puede perder y la boleta queda en *pending*. Mejora: Solid Queue u otra cola persistente, y un botón/tarea
  para reenviar.
- **Webhook sin firma del emisor:** se protege con un token en la URL; con un SII real convendría validar una firma.
- **`documentId` secuencial:** es el id de la boleta; un UUID propio lo haría menos predecible.
- **Capa gratuita en todos los servicios:** arranque en frío de ~1 minuto en Render, pausa de Supabase tras una
  semana sin actividad, y Clerk en modo desarrollo. Para producción habría que pasar a planes de pago o equivalentes,
  una instancia de producción de Clerk (`clerk deploy`) y una cola de jobs persistente.
