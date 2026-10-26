import { useEffect, useState } from 'react'
import type { Product } from '../api/products'
import { useCart } from '../cart/useCart'

const MAX_QUANTITY = 99

export function AddToCart({ product }: { product: Product }) {
  const { addItem } = useCart()
  const [quantity, setQuantity] = useState(1)
  const [added, setAdded] = useState(false)

  useEffect(() => {
    if (!added) return
    const timeout = setTimeout(() => setAdded(false), 1500)
    return () => clearTimeout(timeout)
  }, [added])

  const clamp = (value: number) => Math.min(MAX_QUANTITY, Math.max(1, value))

  const handleAdd = () => {
    addItem(product, quantity)
    setQuantity(1)
    setAdded(true)
  }

  return (
    <div className="add-to-cart">
      <div className="quantity-picker">
        <button
          type="button"
          aria-label="Disminuir cantidad"
          onClick={() => setQuantity((q) => clamp(q - 1))}
          disabled={quantity <= 1}
        >
          −
        </button>
        <input
          type="number"
          aria-label={`Cantidad de ${product.name}`}
          min={1}
          max={MAX_QUANTITY}
          value={quantity}
          onChange={(e) => setQuantity(clamp(Number(e.target.value) || 1))}
        />
        <button
          type="button"
          aria-label="Aumentar cantidad"
          onClick={() => setQuantity((q) => clamp(q + 1))}
          disabled={quantity >= MAX_QUANTITY}
        >
          +
        </button>
      </div>
      <button type="button" className="button" onClick={handleAdd}>
        {added ? '¡Agregado!' : 'Agregar al carrito'}
      </button>
    </div>
  )
}
