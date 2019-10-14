# ANZARD - Australian & New Zealand Assisted Reproduction Database
# Copyright (C) 2017 Intersect Australia Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

Anzard::Application.routes.draw do
  devise_for :users, :controllers => {:registrations => "user_registers", :passwords => "user_passwords"}

  as :user do
    get "/users/profile", :to => "user_registers#profile" #page which gives options to edit details or change password
    get "/users/edit_password", :to => "user_registers#edit_password" #allow users to edit their own password
    put "/users/update_password", :to => "user_registers#update_password" #allow users to edit their own password
  end

  resources :responses, :only => [:index, :new, :create, :edit, :update, :show, :destroy] do
    member do
      get :review_answers
      post :submit
    end
    collection do
      get :download_index_summary
      get :submission_summary
      get :download_submission_summary
      get :prepare_download
      get :download
      get :get_sites
      get :batch_delete
      put :confirm_batch_delete
      put :perform_batch_delete
    end
  end

  resources :clinics, :only => [:index, :new, :create, :edit, :update] do
    collection do
      get :edit_unit
      post :update_unit
    end

    member do
      post :deactivate
      post :activate
    end
  end

  resources :configuration_items, :only => [] do
    collection do
      get :edit_year_of_registration
      put :update_year_of_registration
    end
  end

  resources :batch_files, :only => [:new, :create, :index] do
    collection do
      get :download_index_summary
    end

    member do
      get :summary_report
      get :detail_report
      post :force_submit
    end
  end

  resource :pages do
    get :home
  end

  namespace :admin do
    resources :users, :only => [:show, :index] do

        collection do
          get :access_requests
        end

        member do
          put :reject
          put :reject_as_spam
          put :deactivate
          put :activate
          get :edit_role
          patch :update_role
          get :edit_approval
          patch :approve
          get :get_active_sites

        end
      end

  end

  root :to => "pages#home"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
