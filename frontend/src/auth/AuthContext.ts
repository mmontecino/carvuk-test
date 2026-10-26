import { createContext } from 'react'
import type { Credentials, Registration, Session } from '../api/auth'

export type AuthContextValue = {
  session: Session | null
  login: (credentials: Credentials) => Promise<void>
  register: (registration: Registration) => Promise<void>
  logout: () => Promise<void>
}

export const AuthContext = createContext<AuthContextValue | null>(null)
