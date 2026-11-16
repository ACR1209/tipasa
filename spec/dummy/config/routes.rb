Rails.application.routes.draw do
  mount Tipasa::Engine, at: "/tours"
  get "page", to: "pages#show"
end
