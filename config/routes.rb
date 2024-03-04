Rails.application.routes.draw do
  resources :time_slots, only: [:index, :show, :create, :destroy]

  resources :book_slots, only: :index

  root to: "book_slots#index"
end
