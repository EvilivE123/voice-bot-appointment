Rails.application.routes.draw do
  resources :time_slots, only: [:index, :show, :create, :destroy]

  resources :book_slots, only: :index do
    collection do
      put :book_slot
      put :reschedule
    end
  end

  root to: "book_slots#index"
end
