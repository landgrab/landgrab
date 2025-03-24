# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users,
             controllers: {
               registrations: 'registrations',
               passwords: 'passwords'
             }
  as :user do
    get '/settings/profile' => 'registrations#edit', as: 'edit_profile'
    get '/settings/password' => 'registrations#edit_password', as: 'custom_edit_password'
  end

  root to: 'static_pages#homepage'

  resources :comments, only: %i[create update destroy]

  resources :teams, only: %i[show] do
    get :posts, on: :member
  end

  resources :tiles, only: %i[index show] do
    get :embed, on: :member
    get :posts, on: :member
  end

  resources :plots, only: %i[show] do
    get :embed, on: :member
    get :posts, on: :member
  end

  resources :posts, only: %i[show] do
    get 'access/:access_key', action: :access, on: :member, as: :access
  end

  resources :projects, only: %i[index show] do
    get :find_tile, on: :member
    get :posts, on: :member
    get :welcome, on: :member
  end

  resources :redemption_invites, path: 'invites', only: %i[create] do
    get 'redeem/:token', on: :member, action: :redeem, as: :redeem
  end

  resources :subscriptions, only: %i[index show] do
    delete :cancel, on: :member
    post :redeem, on: :member, action: :redeem_own, as: :redeem_own

    post :manage_billing, on: :collection

    # TODO: Remove GET option once all links are updated to use POST
    match 'link_tile/:tile_hashid', on: :member, action: :link_tile, as: :link_tile, via: %i[get post]
  end

  get '/checkout/checkout', 'checkouts#checkout'
  get '/checkout/generate', 'checkouts#generate'
  get '/checkout/success', 'checkouts#success'

  get '/about', to: 'static_pages#about'
  get '/explore', to: 'static_pages#explore'
  get '/my_tile', to: 'static_pages#my_tile'
  get '/support', to: 'static_pages#support'

  get '/debug', to: 'static_pages#debug'

  namespace :admin do
    root to: 'dashboard#dashboard', as: :dashboard

    resources :comments, only: %i[index show]
    resources :teams, only: %i[create index show new edit update]
    resources :tiles, only: %i[create index show new]
    resources :plots, only: %i[create index show new edit update]
    resources :posts, only: %i[create index show new edit update] do
      get :bulk_association_edit, on: :member
      post :bulk_association_update, on: :member
    end
    resources :post_associations, only: %i[create destroy]
    resources :post_views, only: %i[index]
    resources :prices, only: %i[create index show new edit update]
    resources :projects, only: %i[create index show new edit update]
    resources :promo_codes, only: %i[index]
    resources :redemption_invites, only: %i[create index]
    resources :subscriptions, only: %i[create index show edit update] do
      get :refresh, on: :member
    end
    resources :users, only: %i[index show edit update]
  end

  namespace :webhook do
    post '/stripe' => 'stripe#webhook'
  end
end
