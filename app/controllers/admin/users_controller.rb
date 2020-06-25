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

  before_action only:[:show, :deactivate, :activate, :reject, :reject_as_spam, :edit_role, :edit_approval, :update_role, :approve] do
    redirect_back(fallback_location: root_path, alert: 'Please select a capture system before this action.') if current_capturesystem.users.find_by(id:params[:id].to_i).nil?
  end

  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
    set_tab :users, :admin_navigation
    sort = sort_column + ' ' + sort_direction
    sort = sort + ", #{SECONDARY_SORT_COLUMN} ASC" unless sort_column == SECONDARY_SORT_COLUMN # add secondary sort so its predictable when there's multiple values

    @users = current_capturesystem.users.where(capturesystem_users:{access_status:[CapturesystemUser::STATUS_ACTIVE, CapturesystemUser::STATUS_DEACTIVATED]}).deactivated_or_approved.includes(:role).includes(:clinics).order(sort)
    @clinic_filter = { unit: params[:users_clinic_unit_filter], unit_and_site: params[:users_clinic_site_filter] }
    filter_users_by_unit_code @clinic_filter[:unit], @clinic_filter[:unit]
    filter_users_by_clinic_ids @clinic_filter[:unit_and_site], @clinic_filter[:unit_and_site]
  end

  def show
  end

  def access_requests
    return redirect_back(fallback_location: root_path, alert: 'Please select a capture system first for the Access Requests page.') if at_master_site?
    set_tab :access_requests, :admin_navigation
    @users = current_capturesystem.users.where(capturesystem_users:{access_status:[CapturesystemUser::STATUS_UNAPPROVED, nil, '']}).order(:email)
  end

  def deactivate
    #if !@user.check_number_of_superusers(params[:id], current_user.id)
    the_capturesystem = last_admin_in_any_capturesystem(current_user.id)
    if current_user.id == params[:id].to_i && !the_capturesystem.nil?
      redirect_to(admin_user_path(@user), alert: "You cannot deactivate this account as it is the only account with Administrator privileges in capture system[#{the_capturesystem.name}].")
    else
      #@user.deactivate
      @user.deactivate_in_capturesystem(current_capturesystem)
      redirect_to(admin_user_path(@user), notice: "The user has been deactivated in #{current_capturesystem.name}.")
    end
  end

  def activate
    if @user.clinics.where(capturesystem:current_capturesystem).empty? && !@user.role.super_user?
      redirect_to(admin_user_path(@user), alert: "You cannot activate this account as it is not associated with any sites. Edit this user's site allocation before activating.")
    else
      @user.activate
      @user.activate_in_capturesystem(current_capturesystem)
      redirect_to(admin_user_path(@user), notice: "The user has been activated in #{current_capturesystem.name}.")
    end
  end

  #TODO need cleanup
  def reject
    @user.reject_access_request(CapturesystemUtils.master_site_name, current_capturesystem)
    #@user.destroy
    #reject account request to one capturesystem does not imply rejecting account request to the other
    @user.capturesystem_users.where(capturesystem_id:current_capturesystem.id).destroy_all
    if @user.capturesystem_users.where(access_status: CapturesystemUser::STATUS_ACTIVE).count > 0
      @user.update(status: User::STATUS_ACTIVE)
    elsif @user.capturesystem_users.where(access_status: [CapturesystemUser::STATUS_UNAPPROVED, '', nil]).count > 0
      @user.update(status: User::STATUS_UNAPPROVED)
    elsif @user.capturesystem_users.where(access_status: CapturesystemUser::STATUS_DEACTIVATED).count > 0
      @user.update(status: User::STATUS_DEACTIVATED)
    elsif @user.capturesystem_users.where(access_status: CapturesystemUser::STATUS_REJECTED).count == @user.capturesystem_users.count
      #only remove the account record where all the access requests have been rejected
      if Response.find_by(user:@user) || BatchFile.find_by(user:@user) || ClinicAllocation.find_by(user:@user)
        return redirect_to(access_requests_admin_users_path, alert: "Skipped to remove an existing contributor.")
      else
        if @user.capturesystem_users.destroy_all
          removed_user=@user.destroy
          if removed_user&.destroyed?
            logger.warn("All account request(s) from email [#{removed_user.email}] have been rejected.")
          end
        end
      end
    end

    redirect_to(access_requests_admin_users_path, notice: "The access request for #{@user.email} was rejected.")
  end

  def reject_as_spam
    if @user.capturesystem_users.where(access_status:[CapturesystemUser::STATUS_ACTIVE, CapturesystemUser::STATUS_DEACTIVATED]).count > 0
      return redirect_to(access_requests_admin_users_path, 
        alert: "Cannot permanently block #{@user.email}, it has been approved in the other capture system(s). However you can reject this request with the 'Reject' button.")
    else
      @user.reject_access_request(CapturesystemUtils.master_site_name, current_capturesystem)
      return redirect_to(access_requests_admin_users_path, 
        notice: "The access request for #{@user.email} was rejected and this email address will be permanently blocked.")
    end
  end

  def edit_role
    if @user == current_user
      flash.now[:alert] = 'You are changing the access level of the user you are logged in as.'
    elsif @user.rejected_in_capturesystem?(current_capturesystem)
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
      updated_user_clinics = current_capturesystem.clinics.find(params[:user][:clinic_ids].reject{ |clinic_id| clinic_id.blank? })
      if updated_user_clinics.empty? && !@user.super_user?
        # Don't modify clinic association (which doesn't revert if clinic is invalid) if clinic set is empty and user isn't admin.
        redirect_to(edit_role_admin_user_path(@user), alert: 'Users with this Role must be assigned to a Unit and Site(s)')
      else
        #@user.clinics = updated_user_clinics
        @user.clinic_allocations.where(clinic: @user.clinics.where(capturesystem:current_capturesystem)).destroy_all
        updated_user_clinics.each do |selected_clinic|
          @user.clinics << selected_clinic
        end

        #if !@user.check_number_of_superusers(params[:id], current_user.id)
        the_capturesystem = last_admin_in_any_capturesystem(current_user.id)
        if current_user.id == params[:id].to_i && !the_capturesystem.nil?
          redirect_to(edit_role_admin_user_path(@user), alert: "Only one superuser exists in capture system [#{the_capturesystem.name}]. You cannot change this role.")
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
      selected_clinic_ids = params[:user][:clinic_ids].reject{ |clinic_id| clinic_id.blank? }
      begin
        #@user.clinics = current_capturesystem.clinics.find(params[:user][:clinic_ids].reject{ |clinic_id| clinic_id.blank? })
        @user.clinic_allocations.where(clinic: @user.clinics.where(capturesystem:current_capturesystem)).destroy_all
        selected_clinic_ids.each do |clinic_id|
          @user.clinics << current_capturesystem.clinics.find(clinic_id)
        end
      rescue ActiveRecord::RecordNotFound => invalid
        return redirect_back(fallback_location: root_path, alert: "#{invalid.record.errors.full_messages}")
      rescue ActiveRecord::RecordInvalid => invalid
        return redirect_back(fallback_location: root_path, alert: "#{invalid.record.errors.full_messages}")
      end

      if @user.save
        @user.approve_access_request(CapturesystemUtils.master_site_name, CapturesystemUtils.master_site_base_url, current_capturesystem)
        redirect_to(access_requests_admin_users_path, notice: "The access request for #{@user.email} was approved.")
      else
        redirect_to(edit_approval_admin_user_path(@user), alert: 'Users with this Role must be assigned to a Unit and Site(s)')
      end
    end
  end


  def get_active_sites
    render json: Clinic.where(capturesystem_id: current_capturesystem.id, unit_code: params['unit_code'], active: true)
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

  # returns the first capturesystem that this user is the last admin of
  def last_admin_in_any_capturesystem(user_id)
    User.find_by(id:user_id).capturesystems.each do |cs|
      return cs if cs.users.approved_superusers.where(capturesystem_users: {access_status: CapturesystemUser::STATUS_ACTIVE}).length < 2
    end

    return nil
  end

end
