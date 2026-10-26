export type ReceiptItem = {
  product_id: number
  name: string
  unit_price: string
  amount: number
  subtotal: string
}

export type Receipt = {
  id: number
  net_value: string
  taxes: string
  total_value: string
  created_at: string
  items: ReceiptItem[]
}

export type ReceiptItemInput = {
  product_id: number
  amount: number
}

export class ApiError extends Error {
  readonly status: number

  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

async function request<T>(token: string, init: RequestInit = {}, signal?: AbortSignal): Promise<T> {
  const response = await fetch('/api/receipts', {
    ...init,
    signal,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
    },
  })
  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    const messages: string[] = data.errors ?? (data.error ? [data.error] : [])
    throw new ApiError(response.status, messages.join('. ') || `Error ${response.status}`)
  }
  return data
}

export function fetchReceipts(token: string, signal?: AbortSignal) {
  return request<Receipt[]>(token, {}, signal)
}

export function createReceipt(token: string, items: ReceiptItemInput[]) {
  return request<Receipt>(token, {
    method: 'POST',
    body: JSON.stringify({ receipt: { items } }),
  })
}
