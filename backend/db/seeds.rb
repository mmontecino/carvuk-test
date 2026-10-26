# Product catalog (CLP, tax included). Idempotent: running it again leaves
# existing products untouched.
PRODUCTS = {
  "Huevo" => 300,
  "Leche Descremada" => 1200,
  "Coca Cola Zero 1,5L" => 1400,
  "Pan Marraqueta 1 kg" => 2200,
  "Arroz Grado 1 1 kg" => 1500,
  "Fideos Spaghetti 400 g" => 1100,
  "Aceite de Maravilla 1 L" => 2800,
  "Azúcar 1 kg" => 1300,
  "Mantequilla 250 g" => 2600,
  "Café Instantáneo 170 g" => 4500,
  "Agua Mineral 1,5 L" => 900,
  "Jugo de Naranja 1 L" => 1600,
  "Yogurt Natural 1 kg" => 2300
}.freeze

PRODUCTS.each do |name, price|
  Product.find_or_create_by!(name: name) { |product| product.price = price }
end
