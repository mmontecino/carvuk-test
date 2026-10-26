import { Link } from 'react-router'
import { useCart } from '../cart/useCart'

export function CartButton() {
  const { totalQuantity } = useCart()

  return (
    <Link
      to="/cart"
      className="cart-button"
      aria-label={`Carrito, ${totalQuantity} ${totalQuantity === 1 ? 'producto' : 'productos'}`}
    >
      <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
        <path
          d="M3 4h2l2.4 10.2a1 1 0 0 0 1 .8h8.9a1 1 0 0 0 1-.76L20 8H6.2"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <circle cx="9" cy="19" r="1.5" fill="currentColor" />
        <circle cx="17" cy="19" r="1.5" fill="currentColor" />
      </svg>
      {totalQuantity > 0 && <span className="cart-badge">{totalQuantity}</span>}
    </Link>
  )
}
