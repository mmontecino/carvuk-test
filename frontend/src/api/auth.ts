export type User = {
  id: number
  name: string
  email: string
}

export type Session = {
  token: string
  user: User
}

export type Credentials = {
  email: string
  password: string
}

export type Registration = Credentials & {
  name: string
  password_confirmation: string
}

async function authRequest(path: string, body: object): Promise<Session> {
  const response = await fetch(path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ user: body }),
  })
  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    const messages: string[] = data.errors ?? (data.error ? [data.error] : [])
    throw new Error(messages.join('. ') || `Error ${response.status}`)
  }

  const token = response.headers.get('Authorization')?.replace(/^Bearer /, '')
  if (!token) throw new Error('El servidor no entregó un token')
  return { token, user: data.user }
}

export function signIn(credentials: Credentials) {
  return authRequest('/api/users/sign_in', credentials)
}

export function signUp(registration: Registration) {
  return authRequest('/api/users', registration)
}

export async function signOut(token: string) {
  // Revokes the token on the server; the local session is cleared regardless.
  await fetch('/api/users/sign_out', {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  }).catch(() => {})
}
