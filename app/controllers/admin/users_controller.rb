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

class Admin::UsersController < Admin::AdminBaseController

  ALLOWED_SORT_COLUMNS = %w(email first_name last_name allocated_unit_code roles.name status last_sign_in_at)
  SECONDARY_SORT_COLUMN = 'email'
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
    set_tab :users, :admin_navigation
    sort = sort_column + ' ' + sort_direction
    sort = sort + ", #{SECONDARY_SORT_COLUMN} ASC" unless sort_column == SECONDARY_SORT_COLUMN # add secondary sort so its predictable when there's multiple values

    @users = User.deactivated_or_approved.includes(:role).includes(:clinics).order(sort)
    @clinic_filter = { unit: params[:users_clinic_unit_filter], unit_and_site: params[:users_clinic_site_filter] }
    filter_users_by_unit_code @clinic_filter[:unit], @clinic_filter[:unit]
    filter_users_by_clinic_ids @clinic_filter[:unit_and_site], @clinic_filter[:unit_and_site]
  end

  def show
  end

  def access_requests
    set_tab :access_requests, :admin_navigation
    @users = User.pending_approval
  end

  def deactivate
    if !@user.check_number_of_superusers(params[:id], current_user.id)
      redirect_to(admin_user_path(@user), alert: 'You cannot deactivate this account as it is the only account with Administrator privileges.')
    else
      @user.deactivate
      redirect_to(admin_user_path(@user), notice: 'The user has been deactivated.')
    end
  end

  def activate
    if @user.clinics.empty?
      redirect_to(admin_user_path(@user), alert: "You cannot activate this account as it is not associated with any sites. Edit this user's site allocation before activating.")
    else
      @user.activate
      redirect_to(admin_user_path(@user), notice: 'The user has been activated.')
    end
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
      flash.now[:alert] = 'You are changing the access level of the user you are logged in as.'
    elsif @user.rejected?
      redirect_to(admin_users_path, alert: 'Access level can not be set. This user has previously been rejected as a spammer.')
    end
    @roles = Role.by_name
  end

  def edit_approval
    @roles = Role.by_name
  end

  def update_role
    if params[:user][:role_id].blank?
      redirect_to(edit_role_admin_user_path(@user), alert: 'Please select a role for the user.')
    else
      @user.role_id = params[:user][:role_id]
      # ToDo: Refactor as this duplicates the user clinic validation which isn't ideal.
      updated_user_clinics = Clinic.find(params[:user][:clinic_ids].reject{ |clinic_id| clinic_id.blank? })
      if updated_user_clinics.empty? && !@user.super_user?
        # Don't modify clinic association (which doesn't revert if clinic is invalid) if clinic set is empty and user isn't admin.
        redirect_to(edit_role_admin_user_path(@user), alert: 'Users with this Role must be assigned to a Unit and Site(s)')
      else
        @user.clinics = updated_user_clinics
        if !@user.check_number_of_superusers(params[:id], current_user.id)
          redirect_to(edit_role_admin_user_path(@user), alert: 'Only one superuser exists. You cannot change this role.')
        elsif @user.save
          redirect_to(admin_user_path(@user), notice: "The access level for #{@user.email} was successfully updated.")
        else
          redirect_to(edit_role_admin_user_path(@user), alert: 'Users with this Role must be assigned to a Unit and Site(s)')
        end
      end
    end
  end

  def approve
    if params[:user][:role_id].blank?
      redirect_to(edit_approval_admin_user_path(@user), alert: 'Please select a role for the user.')
    else
      @user.role_id = params[:user][:role_id]
      @user.clinics = Clinic.find(params[:user][:clinic_ids].reject{ |clinic_id| clinic_id.blank? })
      if @user.save
        @user.approve_access_request
        redirect_to(access_requests_admin_users_path, notice: "The access request for #{@user.email} was approved.")
      else
        redirect_to(edit_approval_admin_user_path(@user), alert: 'Users with this Role must be assigned to a Unit and Site(s)')
      end
    end
  end


  def get_active_sites
    render json: Clinic.where(unit_code: params['unit_code'], active: true)
  end

  private
  def sort_column
    ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : SECONDARY_SORT_COLUMN
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def filter_users_by_unit_code(selected_filter_option, unit_code)
    if selected_filter_option == 'None'
      @users = @users.where(allocated_unit_code: nil)
    elsif !selected_filter_option.blank?
      @users = @users.where(allocated_unit_code: unit_code)
    end
  end

  def filter_users_by_clinic_ids(selected_filter_option, clinic_ids)
    if selected_filter_option == 'None'
      @users = @users.where('users.id NOT IN (SELECT user_id FROM clinic_allocations)')
    elsif !selected_filter_option.blank?
      matching_clinic_allocations = ClinicAllocation.where(clinic_id: clinic_ids, user_id: @users.pluck(:id))
      if matching_clinic_allocations.nil?
        @users = nil
      else
        @users = @users.where(id: matching_clinic_allocations.pluck(:user_id))
      end
    end
  end

end
