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

class UserPasswordsController < Devise::PasswordsController

  def create
    # Override the devise controller so we don't show errors (since we don't want to reveal if the email exists)
    # https://github.com/plataformatec/devise/blob/v1.4.2/app/controllers/devise/passwords_controller.rb
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])

    # the only error we show is the empty email one
    if params[resource_name][:email].empty?
      respond_with_navigational(resource){ render :new }
    else
      set_flash_message(:notice, :send_paranoid_instructions) if is_navigational_format?
      redirect_to(new_user_session_path)
    end
  end

end