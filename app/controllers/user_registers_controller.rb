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

class UserRegistersController < Devise::RegistrationsController

  prepend_before_action :authenticate_scope!, only: [:edit, :update, :destroy, :edit_password, :update_password, :profile]

  def profile

  end

  # Override the create method in the RegistrationsController to add the notification hook
  # https://github.com/plataformatec/devise/blob/v4.2.0/app/controllers/devise/registrations_controller.rb#L14
  def create
    build_resource(sign_up_params)

    if resource.save
      capturesystem = current_capturesystem
      if !capturesystem.nil?
        capturesystem_user = CapturesystemUser.new
        capturesystem_user.capturesystem = capturesystem
        capturesystem_user.user = resource
        if capturesystem_user.save
          logger.debug("Created new capturesystem_user [#{capturesystem.name}:#{resource.email}]")
        else
          logger.error("Failed to create new capturesystem_user [#{capturesystem.name} : #{resource.email}]")
        end
      end
    end

    yield resource if block_given?
    if resource.persisted?
      Notifier.notify_superusers_of_access_request(resource, current_capturesystem).deliver
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # Override the update method in the RegistrationsController so that we don't require password on update
  # https://github.com/plataformatec/devise/blob/v1.3.4/app/controllers/devise/registrations_controller.rb
  def update
    if resource.update_attributes(params.require(resource_name).permit(:first_name, :last_name))
      set_flash_message :notice, :updated if is_navigational_format?
      sign_in resource_name, resource, bypass: true
      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource){ render :edit }
    end
  end

  def edit_password
    render :edit_password
  end

  # Mostly the same as the devise 'update' method, just call a different method on the model
  def update_password
    if resource.update_password(params.require(resource_name).permit(:current_password, :password, :password_confirmation))
      set_flash_message :notice, :password_updated if is_navigational_format?
      sign_in resource_name, resource, bypass: true
      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource){ render :edit_password }
    end
  end

end

