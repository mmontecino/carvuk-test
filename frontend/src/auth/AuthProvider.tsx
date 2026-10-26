import { useCallback, useMemo, useState, type ReactNode } from 'react'
import { signIn, signOut, signUp, type Session } from '../api/auth'
import { AuthContext, type AuthContextValue } from './AuthContext'
import { loadSession, saveSession } from './session'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(loadSession)

  const update = useCallback((next: Session | null) => {
    saveSession(next)
    setSession(next)
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      login: async (credentials) => update(await signIn(credentials)),
      register: async (registration) => update(await signUp(registration)),
      logout: async () => {
        if (session) await signOut(session.token)
        update(null)
      },
    }),
    [session, update],
  )

  return <AuthContext value={value}>{children}</AuthContext>
}
