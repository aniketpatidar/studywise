Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "signup", to: "users#new"
  resources :users, only: :create
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  root "dashboard#index"

  resources :materials do
    post :generate_note, on: :member
    post :generate_quiz, on: :member
    member do
      get :study_chat, to: "study_chats#show"
      post :study_chat, to: "study_chats#create"
    end
    resources :quizzes, only: :show do
      post :submit, on: :member
    end
    resources :notes, only: :index do
      post :share, on: :member
    end
  end

  resources :subject_chats, only: %i[index show create]
  get "s/:share_token", to: "shared_notes#show", as: :shared_note
end
