// Cloudflare Pages Function: forwards /api/* to the Rails API (the SPA calls
// relative /api URLs, like the Vite proxy does in development).
// Set API_ORIGIN (e.g. https://carvuk-api.onrender.com) in the Pages project.
interface Env {
  API_ORIGIN?: string
}

export async function onRequest({ request, env }: { request: Request; env: Env }) {
  if (!env.API_ORIGIN) {
    return Response.json({ error: 'API_ORIGIN is not configured' }, { status: 500 })
  }

  const { pathname, search } = new URL(request.url)
  const target = new URL(pathname + search, env.API_ORIGIN)

  // The Request keeps method, headers (Authorization included) and body.
  return fetch(new Request(target, request), { redirect: 'manual' })
}
