class UserRegistersController < Devise::RegistrationsController

  prepend_before_action :authenticate_scope!, only: [:edit, :update, :destroy, :edit_password, :update_password, :profile]

  def profile

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

