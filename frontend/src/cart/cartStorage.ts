export type CartItem = {
  productId: number
  name: string
  price: string
  quantity: number
}

const keyFor = (userId: number) => `cart:${userId}`

export function loadCart(userId: number | null): CartItem[] {
  if (userId === null) return []
  try {
    const raw = localStorage.getItem(keyFor(userId))
    return raw ? JSON.parse(raw) : []
  } catch {
    return []
  }
}

export function saveCart(userId: number, items: CartItem[]) {
  try {
    if (items.length > 0) localStorage.setItem(keyFor(userId), JSON.stringify(items))
    else localStorage.removeItem(keyFor(userId))
  } catch {
    // Storage unavailable: the cart lives only in memory.
  }
}
