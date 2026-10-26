import { SignIn, SignUp } from '@clerk/react'
import { useState } from 'react'
import { Navigate } from 'react-router'
import { useAuth } from '../auth/useAuth'

type Mode = 'login' | 'register'

export function LoginPage() {
  const { session } = useAuth()
  const [mode, setMode] = useState<Mode>('login')

  if (session) return <Navigate to="/" replace />

  const isRegister = mode === 'register'

  return (
    <div className="auth-card">
      <div className="auth-tabs" role="tablist">
        <button
          type="button"
          role="tab"
          aria-selected={!isRegister}
          className={!isRegister ? 'active' : ''}
          onClick={() => setMode('login')}
        >
          Ingresar
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={isRegister}
          className={isRegister ? 'active' : ''}
          onClick={() => setMode('register')}
        >
          Crear cuenta
        </button>
      </div>

      {isRegister ? (
        <SignUp routing="hash" signInUrl="/login" fallbackRedirectUrl="/" />
      ) : (
        <SignIn routing="hash" signUpUrl="/login" fallbackRedirectUrl="/" />
      )}
    </div>
  )
}
