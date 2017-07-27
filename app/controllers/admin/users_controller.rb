# ANZNN - Australian & New Zealand Neonatal Network
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

class Admin::UsersController < Admin::AdminBaseController

  ALLOWED_SORT_COLUMNS = %w(email first_name last_name hospitals.name roles.name status last_sign_in_at)
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
    set_tab :users, :admin_navigation
    sort = sort_column + ' ' + sort_direction
    sort = sort + ", email ASC" unless sort_column == "email" # add email as a secondary sort so its predictable when there's multiple values

    @users = User.deactivated_or_approved.includes(:role).includes(:hospital).order(sort)

    @hospital_filter = params[:hospital_filter]
    if @hospital_filter == "None"
      @users = @users.where("users.hospital_id IS NULL")
    elsif !@hospital_filter.blank?
      @users = @users.where(hospital_id: @hospital_filter)
    end
  end

  def show
  end

  def access_requests
    set_tab :access_requests, :admin_navigation
    @users = User.pending_approval
  end

  def deactivate
    if !@user.check_number_of_superusers(params[:id], current_user.id)
      redirect_to(admin_user_path(@user), alert: "You cannot deactivate this account as it is the only account with Administrator privileges.")
    else
      @user.deactivate
      redirect_to(admin_user_path(@user), notice: "The user has been deactivated.")
    end
  end

  def activate
    @user.activate
    redirect_to(admin_user_path(@user), notice: "The user has been activated.")
  end

  def reject
    @user.reject_access_request
    @user.destroy
    redirect_to(access_requests_admin_users_path, notice: "The access request for #{@user.email} was rejected.")
  end

  def reject_as_spam
    @user.reject_access_request
    redirect_to(access_requests_admin_users_path, notice: "The access request for #{@user.email} was rejected and this email address will be permanently blocked.")
  end

  def edit_role
    if @user == current_user
      flash.now[:alert] = "You are changing the access level of the user you are logged in as."
    elsif @user.rejected?
      redirect_to(admin_users_path, alert: "Access level can not be set. This user has previously been rejected as a spammer.")
    end
    @roles = Role.by_name
  end

  def edit_approval
    @roles = Role.by_name
  end

  def update_role
    if params[:user][:role_id].blank?
      redirect_to(edit_role_admin_user_path(@user), alert: "Please select a role for the user.")
    else
      @user.role_id = params[:user][:role_id]
      @user.hospital_id = params[:user][:hospital_id]
      if !@user.check_number_of_superusers(params[:id], current_user.id)
        redirect_to(edit_role_admin_user_path(@user), alert: "Only one superuser exists. You cannot change this role.")
      elsif @user.save
        redirect_to(admin_user_path(@user), notice: "The access level for #{@user.email} was successfully updated.")
      else
        redirect_to(edit_role_admin_user_path(@user), alert: "All non-superusers must be assigned a hospital")
      end
    end
  end

  def approve
    if params[:user][:role_id].blank?
      redirect_to(edit_approval_admin_user_path(@user), alert: "Please select a role for the user.")
    else
      @user.role_id = params[:user][:role_id]
      @user.hospital_id = params[:user][:hospital_id]
      if @user.save
        @user.approve_access_request
        redirect_to(access_requests_admin_users_path, notice: "The access request for #{@user.email} was approved.")
      else
        redirect_to(edit_approval_admin_user_path(@user), alert: "All non-superusers must be assigned a hospital")
      end
    end
  end

  private
  def sort_column
    ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "email"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

end
