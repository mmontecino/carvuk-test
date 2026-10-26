class Api::ProductsController < ApplicationController
  def index
    render json: Product.order(:name).as_json(only: %i[id name price])
  end
end
