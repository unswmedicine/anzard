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

  private
  def sort_column
    ALLOWED_SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_COLUMN
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

end