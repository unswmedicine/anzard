class ClinicsController < ApplicationController
  before_action :authenticate_user!

  ALLOWED_SORT_COLUMNS = %w(unit_name unit_code site_name site_code state)
  DEFAULT_SORT_COLUMN = 'unit_code'
  SECONDARY_SORT_COLUMN = 'site_code'
  load_and_authorize_resource
  helper_method :sort_column, :sort_direction

  def index
    set_tab :clinics, :admin_navigation
    sort = sort_column + ' ' + sort_direction
    sort = sort + ", #{SECONDARY_SORT_COLUMN} ASC" unless sort_column == SECONDARY_SORT_COLUMN # add secondary sort so its predictable when there's multiple values

    @clinic_filter = { unit: params[:clinics_unit_filter] }
    if !@clinic_filter[:unit].blank?
      @clinics = Clinic.where(unit_code: @clinic_filter[:unit]).order(sort)
    else
      @clinics = Clinic.all.order(sort)
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

  private
  def sort_column
    ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_COLUMN
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def clinic_params
    params.require(:clinic).permit(:site_name)
  end

end