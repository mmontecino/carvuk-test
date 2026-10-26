import { useState } from 'react'
import { Link, Navigate } from 'react-router'
import { ApiError, createReceipt, type Receipt } from '../api/receipts'
import { useAuth } from '../auth/useAuth'
import { useCart } from '../cart/useCart'
import { ReceiptDetails } from '../components/ReceiptDetails'
import { formatPrice } from '../utils/formatPrice'

export function CartPage() {
  const { session, getToken, logout } = useAuth()
  const { items, totalPrice, removeItem, clear } = useCart()
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [receipt, setReceipt] = useState<Receipt | null>(null)

  if (!session) return <Navigate to="/login" replace />

  if (receipt) return <PurchaseConfirmation receipt={receipt} />

  const handleCheckout = async () => {
    setSubmitting(true)
    setError(null)
    try {
      const created = await createReceipt(
        getToken,
        items.map((item) => ({ product_id: item.productId, amount: item.quantity })),
      )
      clear()
      setReceipt(created)
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        // Expired or revoked token: the cart is kept for when the user signs back in.
        await logout()
        return
      }
      setError(err instanceof Error ? err.message : 'Error desconocido')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <>
      <h1>Carrito</h1>
      {items.length === 0 ? (
        <div className="cart-empty">
          <p>Tu carrito está vacío.</p>
          <Link to="/" className="button">
            Ver productos
          </Link>
        </div>
      ) : (
        <div className="cart-summary">
          <table className="cart-table">
            <thead>
              <tr>
                <th>Producto</th>
                <th className="numeric">Precio</th>
                <th className="numeric">Cantidad</th>
                <th className="numeric">Subtotal</th>
                <th>
                  <span className="visually-hidden">Acciones</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <tr key={item.productId}>
                  <td>{item.name}</td>
                  <td className="numeric">{formatPrice(item.price)}</td>
                  <td className="numeric">{item.quantity}</td>
                  <td className="numeric">{formatPrice(Number(item.price) * item.quantity)}</td>
                  <td className="actions">
                    <button
                      type="button"
                      className="link-button"
                      onClick={() => removeItem(item.productId)}
                      disabled={submitting}
                    >
                      Quitar
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <th colSpan={3}>Total</th>
                <td className="numeric total">{formatPrice(totalPrice)}</td>
                <td />
              </tr>
            </tfoot>
          </table>

          {error && <p className="form-error">{error}</p>}

          <div className="cart-actions">
            <button type="button" className="button" onClick={handleCheckout} disabled={submitting}>
              {submitting ? 'Procesando…' : 'Finalizar compra'}
            </button>
          </div>
        </div>
      )}
    </>
  )
}

function PurchaseConfirmation({ receipt }: { receipt: Receipt }) {
  return (
    <div className="cart-summary">
      <h1>¡Compra realizada!</h1>
      <p>Boleta N° {receipt.id}</p>
      <p className="confirmation-note">
        Estamos generando tu documento en el SII. Cuando esté listo verás su número y el PDF en{' '}
        <Link to="/receipts">Mis boletas</Link>.
      </p>
      <ReceiptDetails receipt={receipt} />
      <div className="cart-actions">
        <Link to="/" className="button button-secondary">
          Seguir comprando
        </Link>
        <Link to="/receipts" className="button">
          Ver mis boletas
        </Link>
      </div>
    </div>
  )
}
