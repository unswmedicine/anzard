class Admin::UsersController < Admin::AdminBaseController

  ALLOWED_SORT_COLUMNS = %w(email first_name last_name allocated_unit_code roles.name status last_sign_in_at)
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
    set_tab :users, :admin_navigation
    sort = sort_column + ' ' + sort_direction
    sort = sort + ', email ASC' unless sort_column == 'email' # add email as a secondary sort so its predictable when there's multiple values

    @users = User.deactivated_or_approved.includes(:role).includes(:clinics).order(sort)
    @clinic_filter = { unit: params[:clinic_unit_filter], unit_and_site: params[:clinic_site_filter] }
    filter_users @clinic_filter[:unit], Clinic.where(unit_code: @clinic_filter[:unit])
    filter_users @clinic_filter[:unit_and_site], @clinic_filter[:unit_and_site]
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
    @user.activate
    redirect_to(admin_user_path(@user), notice: 'The user has been activated.')
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


  def get_sites
    render json: Clinic.where(unit_code: params['unit_code'])
  end

  private
  def sort_column
    ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : 'email'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def filter_users(selected_filter_option, clinic_ids)
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
