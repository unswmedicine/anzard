class ClinicsController < ApplicationController
  before_action :authenticate_user!

  ALLOWED_SORT_COLUMNS = %w(unit_name unit_code site_name site_code state active)
  DEFAULT_SORT_COLUMN = 'unit_code'
  SECONDARY_SORT_COLUMN = 'unit_code'
  TERTIARY_SORT_COLUMN = 'site_code'
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
    set_tab :clinics, :admin_navigation
    sort = sort_column + ' ' + sort_direction
    # add secondary and tertiary sort so its predictable when there's multiple values and so sites from same unit are grouped together
    sort += ", #{SECONDARY_SORT_COLUMN} ASC" unless sort_column == SECONDARY_SORT_COLUMN
    sort += ", #{TERTIARY_SORT_COLUMN} ASC" unless sort_column == TERTIARY_SORT_COLUMN
    @clinic_filter = { unit: params[:clinics_unit_filter] }
    if !@clinic_filter[:unit].blank?
      @clinics = Clinic.where(unit_code: @clinic_filter[:unit]).order(sort)
    else
      @clinics = Clinic.all.order(sort)
    end
  end

  def new
  end

  def create
    @clinic = Clinic.new(clinic_params)
    if @clinic.save
      redirect_to clinics_path, notice: "Clinic #{@clinic.unit_site_code} was successfully created."
    else
      redirect_to(new_clinic_path(@clinic), alert: @clinic.errors.full_messages.first)
    end
  end

  def edit
  end

  def update
    @clinic.site_name = params[:clinic][:site_name]
    if @clinic.save
      redirect_to clinics_path, notice: "Clinic #{@clinic.unit_site_code} was successfully updated."
    else
      redirect_to(edit_clinic_path(@clinic), alert: @clinic.errors.full_messages.first)
    end
  end

  def edit_unit
  end

  def update_unit
    if params[:updated_unit_name].blank?
      redirect_to(edit_unit_clinics_path, alert: 'Unit Name cannot be blank')
    else
      Clinic.where(unit_code: params[:selected_unit_code]).update_all(unit_name: params[:updated_unit_name])
      redirect_to clinics_path, notice: "Unit #{params[:selected_unit_code]} was successfully updated."
    end
  end

  def activate
    @clinic.activate
    redirect_to(clinics_path, notice: 'The clinic has been activated.')
  end

  def deactivate
    @clinic.deactivate
    allocations_for_clinic = ClinicAllocation.where(clinic: @clinic)
    deactivated_clinic_users = User.where(id: allocations_for_clinic.pluck(:user_id).uniq)
    allocations_for_clinic.destroy_all
    users_deactivated = []
    deactivated_clinic_users.each do |user|
      if user.clinics.empty?
        user.deactivate
        users_deactivated.append user
      end
    end
    notice = 'The clinic has been deactivated.'
    notice += " #{users_deactivated.count} user account(s) have also been automatically deactivated." unless users_deactivated.empty?
    redirect_to(clinics_path, notice: notice)
  end

  private
  def sort_column
    ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_COLUMN
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def clinic_params
    params.require(:clinic).permit(:unit_code, :unit_name, :site_code, :site_name, :state)
  end

end