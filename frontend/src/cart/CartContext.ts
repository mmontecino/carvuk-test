import { createContext } from 'react'
import type { Product } from '../api/products'
import type { CartItem } from './cartStorage'

export type CartContextValue = {
  items: CartItem[]
  totalQuantity: number
  totalPrice: number
  addItem: (product: Product, quantity: number) => void
  removeItem: (productId: number) => void
  clear: () => void
}

export const CartContext = createContext<CartContextValue | null>(null)
