import { Link } from 'react-router'
import { useAuth } from '../auth/useAuth'
import { CartButton } from './CartButton'

export function Header() {
  const { session, logout } = useAuth()

  return (
    <header className="header">
      <Link to="/" className="brand">
        Tienda
      </Link>
      {session ? (
        <div className="header-user">
          <Link to="/receipts" className="user-link" title="Mis compras">
            Hola, {session.user.name}
          </Link>
          <CartButton />
          <button type="button" className="button button-secondary" onClick={logout}>
            Cerrar sesión
          </button>
        </div>
      ) : (
        <Link to="/login" className="button">
          Iniciar sesión
        </Link>
      )}
    </header>
  )
}
