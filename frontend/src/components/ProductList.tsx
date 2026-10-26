import { useEffect, useState } from 'react'
import { fetchProducts, type Product } from '../api/products'
import { useAuth } from '../auth/useAuth'
import { formatPrice } from '../utils/formatPrice'
import { AddToCart } from './AddToCart'

export function ProductList() {
  const { session } = useAuth()
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const controller = new AbortController()
    fetchProducts(controller.signal)
      .then(setProducts)
      .catch((err: unknown) => {
        if (controller.signal.aborted) return
        setError(err instanceof Error ? err.message : 'Error desconocido')
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false)
      })
    return () => controller.abort()
  }, [])

  if (loading) return <p className="status">Cargando productos…</p>
  if (error) return <p className="status error">{error}</p>
  if (products.length === 0) {
    return <p className="status">No hay productos disponibles.</p>
  }

  return (
    <ul className="product-grid">
      {products.map((product) => (
        <li key={product.id} className="product-card">
          <span className="product-name">{product.name}</span>
          <span className="product-price">
            {formatPrice(product.price)}
          </span>
          {session && <AddToCart product={product} />}
        </li>
      ))}
    </ul>
  )
}
