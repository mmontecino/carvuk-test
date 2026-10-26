import { useEffect, useState } from 'react'
import { Link, Navigate } from 'react-router'
import { ApiError, fetchReceipts, type Receipt } from '../api/receipts'
import { useAuth } from '../auth/useAuth'
import { ReceiptDetails } from '../components/ReceiptDetails'
import { formatPrice } from '../utils/formatPrice'

const dateFormatter = new Intl.DateTimeFormat('es-CL', {
  dateStyle: 'medium',
  timeStyle: 'short',
})

const POLL_INTERVAL_MS = 1000

export function ReceiptsPage() {
  const { session, getToken, logout } = useAuth()
  const signedIn = session !== null
  const [receipts, setReceipts] = useState<Receipt[] | null>(null)
  const [error, setError] = useState<string | null>(null)

  const hasPending = receipts?.some((receipt) => receipt.sii_status === 'pending') ?? false

  // Loads the receipts, and keeps refreshing them while the SII is still
  // issuing a document (its result arrives asynchronously through a webhook).
  useEffect(() => {
    if (!signedIn) return
    const controller = new AbortController()
    const load = () =>
      fetchReceipts(getToken, controller.signal)
        .then(setReceipts)
        .catch((err: unknown) => {
          if (controller.signal.aborted) return
          // Expired or revoked token: sign out, which redirects to the login page.
          if (err instanceof ApiError && err.status === 401) return logout()
          setError(err instanceof Error ? err.message : 'Error desconocido')
        })

    load()
    const interval = hasPending ? setInterval(load, POLL_INTERVAL_MS) : undefined
    return () => {
      controller.abort()
      clearInterval(interval)
    }
  }, [signedIn, getToken, logout, hasPending])

  if (!session) return <Navigate to="/login" replace />

  return (
    <>
      <h1>Mis boletas</h1>
      {error ? (
        <p className="status error">{error}</p>
      ) : receipts === null ? (
        <p className="status">Cargando boletas…</p>
      ) : receipts.length === 0 ? (
        <div className="cart-empty">
          <p>Aún no tienes boletas. Tus compras aparecerán aquí.</p>
          <Link to="/" className="button">
            Ver productos
          </Link>
        </div>
      ) : (
        <ul className="receipt-list">
          {receipts.map((receipt) => (
            <li key={receipt.id}>
              <details className="receipt-card">
                <summary>
                  <span className="receipt-title">Boleta N° {receipt.id}</span>
                  <span className="receipt-date">
                    {dateFormatter.format(new Date(receipt.created_at))}
                  </span>
                  <span className="receipt-total">{formatPrice(receipt.total_value)}</span>
                  <span className="receipt-sii">{receipt.sii_code ?? 'SII pendiente'}</span>
                </summary>
                <ReceiptDetails receipt={receipt} />
              </details>
            </li>
          ))}
        </ul>
      )}
    </>
  )
}
