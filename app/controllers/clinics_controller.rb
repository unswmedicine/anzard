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
      @clinics = Clinic.where(capturesystem_id: current_capturesystem.id, unit_code: @clinic_filter[:unit]).order(sort)
    else
      @clinics = Clinic.where(capturesystem_id: current_capturesystem.id).order(sort)
    end
  end

  def new
  end

  def create
    @clinic = Clinic.new(clinic_params)
    @clinic.capturesystem_id = current_capturesystem&.id;
    if @clinic.save
      redirect_to clinics_path, notice: "Clinic #{@clinic.unit_site_code} was successfully created."
    else
      redirect_to(new_clinic_path(@clinic), alert: @clinic.errors.full_messages.first)
    end
  end

  def edit
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') if current_capturesystem.clinics.find_by(id: @clinic.id).nil?
  end

  def update
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') if current_capturesystem.clinics.find_by(id: @clinic.id).nil?

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
      Clinic.where(capturesystem_id: current_capturesystem.id, unit_code: params[:selected_unit_code]).update_all(unit_name: params[:updated_unit_name])
      redirect_to clinics_path, notice: "Unit #{params[:selected_unit_code]} was successfully updated."
    end
  end

  def activate
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') if current_capturesystem.clinics.find_by(id: @clinic.id).nil?
    @clinic.activate
    redirect_to(clinics_path, notice: 'The clinic has been activated.')
  end

  def deactivate
    return redirect_back(fallback_location: root_path, alert: 'Can not access unidentifieable resource.') if current_capturesystem.clinics.find_by(id: @clinic.id).nil?
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