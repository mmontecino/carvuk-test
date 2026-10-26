import { createContext } from 'react'

export type SessionUser = {
  id: string
  name: string
  email: string
}

export type AuthContextValue = {
  session: { user: SessionUser } | null
  getToken: () => Promise<string>
  logout: () => Promise<void>
}

export const AuthContext = createContext<AuthContextValue | null>(null)
