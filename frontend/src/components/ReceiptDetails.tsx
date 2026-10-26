import type { Receipt } from '../api/receipts'
import { formatPrice } from '../utils/formatPrice'

export function ReceiptDetails({ receipt }: { receipt: Receipt }) {
  return (
    <table className="cart-table">
      <thead>
        <tr>
          <th>Producto</th>
          <th className="numeric">Precio</th>
          <th className="numeric">Cantidad</th>
          <th className="numeric">Subtotal</th>
        </tr>
      </thead>
      <tbody>
        {receipt.items.map((item) => (
          <tr key={item.product_id}>
            <td>{item.name}</td>
            <td className="numeric">{formatPrice(item.unit_price)}</td>
            <td className="numeric">{item.amount}</td>
            <td className="numeric">{formatPrice(item.subtotal)}</td>
          </tr>
        ))}
      </tbody>
      <tfoot>
        <tr>
          <th colSpan={3}>Neto</th>
          <td className="numeric">{formatPrice(receipt.net_value)}</td>
        </tr>
        <tr>
          <th colSpan={3}>IVA</th>
          <td className="numeric">{formatPrice(receipt.taxes)}</td>
        </tr>
        <tr>
          <th colSpan={3}>Total</th>
          <td className="numeric total">{formatPrice(receipt.total_value)}</td>
        </tr>
      </tfoot>
    </table>
  )
}
