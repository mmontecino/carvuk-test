Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "webhooks/sii", to: "webhooks/sii#create", defaults: { format: :json }

  namespace :api, defaults: { format: :json } do
    resources :products, only: :index
    resources :receipts, only: %i[index show create]
  end
end
