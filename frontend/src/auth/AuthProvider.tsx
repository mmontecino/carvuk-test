import { useAuth as useClerkAuth, useClerk, useUser } from '@clerk/react'
import { useCallback, useMemo, type ReactNode } from 'react'
import { AuthContext, type AuthContextValue } from './AuthContext'

// Adapts Clerk to the small context the rest of the app uses.
export function AuthProvider({ children }: { children: ReactNode }) {
  const { getToken } = useClerkAuth()
  const { signOut } = useClerk()
  const { isLoaded, user } = useUser()

  const getSessionToken = useCallback(async () => {
    const token = await getToken()
    if (!token) throw new Error('No hay una sesión activa')
    return token
  }, [getToken])

  const value = useMemo<AuthContextValue>(
    () => ({
      session: user
        ? {
            user: {
              id: user.id,
              name: user.fullName ?? user.username ?? user.primaryEmailAddress?.emailAddress ?? '',
              email: user.primaryEmailAddress?.emailAddress ?? '',
            },
          }
        : null,
      getToken: getSessionToken,
      logout: () => signOut({ redirectUrl: '/' }),
    }),
    [user, getSessionToken, signOut],
  )

  // Wait for Clerk so protected pages don't redirect to /login while it loads.
  if (!isLoaded) return <p className="status">Cargando…</p>

  return <AuthContext value={value}>{children}</AuthContext>
}
