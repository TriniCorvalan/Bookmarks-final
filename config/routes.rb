Rails.application.routes.draw do
  resources :bookmarks
  resources :categories
  resources :kinds
  get "categories/:id/api", to: "categories#api", as: "api"
  root to: 'home#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
