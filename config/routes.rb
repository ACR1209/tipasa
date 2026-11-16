Tipasa::Engine.routes.draw do
  get ":slug", to: "tours#show", as: :tour
  post ":slug/complete", to: "tours#complete", as: :complete_tour
end
