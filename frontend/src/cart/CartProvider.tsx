import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Product } from '../api/products'
import { useAuth } from '../auth/useAuth'
import { CartContext, type CartContextValue } from './CartContext'
import { loadCart, saveCart, type CartItem } from './cartStorage'

// The cart is client-side and stored per user, so it survives reloads and logouts.
export function CartProvider({ children }: { children: ReactNode }) {
  const { session } = useAuth()
  const userId = session?.user.id ?? null
  const [cart, setCart] = useState(() => ({ userId, items: loadCart(userId) }))

  // Swap to the stored cart of whoever is signed in now.
  if (cart.userId !== userId) {
    setCart({ userId, items: loadCart(userId) })
  }

  useEffect(() => {
    if (cart.userId !== null) saveCart(cart.userId, cart.items)
  }, [cart])

  const addItem = useCallback((product: Product, quantity: number) => {
    setCart((current) => {
      const existing = current.items.find((item) => item.productId === product.id)
      const items: CartItem[] = existing
        ? current.items.map((item) =>
            item === existing ? { ...item, quantity: item.quantity + quantity } : item,
          )
        : [
            ...current.items,
            { productId: product.id, name: product.name, price: product.price, quantity },
          ]
      return { ...current, items }
    })
  }, [])

  const removeItem = useCallback((productId: number) => {
    setCart((current) => ({
      ...current,
      items: current.items.filter((item) => item.productId !== productId),
    }))
  }, [])

  const clear = useCallback(() => {
    setCart((current) => ({ ...current, items: [] }))
  }, [])

  const value = useMemo<CartContextValue>(
    () => ({
      items: cart.items,
      totalQuantity: cart.items.reduce((sum, item) => sum + item.quantity, 0),
      totalPrice: cart.items.reduce((sum, item) => sum + Number(item.price) * item.quantity, 0),
      addItem,
      removeItem,
      clear,
    }),
    [cart.items, addItem, removeItem, clear],
  )

  return <CartContext value={value}>{children}</CartContext>
}
