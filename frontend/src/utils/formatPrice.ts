const priceFormatter = new Intl.NumberFormat('es-CL', {
  style: 'currency',
  currency: 'CLP',
})

export function formatPrice(value: string | number) {
  return priceFormatter.format(Number(value))
}
