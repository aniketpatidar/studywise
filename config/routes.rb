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
  match "auth/google_oauth2/callback", to: "oauth_callbacks#google", via: %i[get post]
  match "auth/failure", to: "oauth_callbacks#failure", via: %i[get post]
  delete "logout", to: "sessions#destroy"

  root "landing#index"
  get "admin", to: "dashboard#index"
  get "dashboard", to: redirect("/admin")

  resources :materials do
    post :import_sample, on: :collection
    post :generate_note, on: :member
    post :generate_quiz, on: :member
    get :preview_extraction, on: :member
    member do
      get :study_chat, to: "study_chats#show"
      post :study_chat, to: "study_chats#create"
      post :stream_study_chat, to: "study_chats#stream"
      post :regenerate_study_chat, to: "study_chats#regenerate"
      delete :study_chat, to: "study_chats#destroy"
    end
    resources :quizzes, only: :show do
      post :submit, on: :member
    end
    resources :notes, only: :index do
      post :share, on: :member
    end
  end

  resources :subject_chats, path: "tutors", only: %i[index show create] do
    post :stream, on: :member
  end
  get "subject_chats", to: redirect("/tutors")
  get "subject_chats/:id", to: redirect("/tutors/%{id}")
  namespace :admin do
    resources :llm_events, only: :show
  end
  get "s/:share_token", to: "shared_notes#show", as: :shared_note
end
