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

class ConfigurationItemsController < ApplicationController

  before_action :authenticate_user!
  load_and_authorize_resource
  set_tab :year_of_registration, :admin_navigation

  def edit_year_of_registration
    load_values
  end

  def update_year_of_registration
    start_year = params[:start_year] || ""
    end_year = params[:end_year] || ""
    load_values
    @errors = validate_and_save(start_year, end_year)
    if @errors.empty?
      redirect_to(edit_year_of_registration_configuration_items_path, notice: "Year of registration range updated successfully.")
    else
      render :edit_year_of_registration
    end
  end

  private
  def validate_and_save(start_year, end_year)
    @start_year.configuration_value = start_year.strip
    @end_year.configuration_value = end_year.strip
    errors = []
    errors << "Start year is required" if @start_year.configuration_value.blank?
    errors << "End year is required" if @end_year.configuration_value.blank?
    errors << "Start year must be a number" unless (@start_year.configuration_value.blank? || @start_year.configuration_value =~ /\A(\d+)\Z/)
    errors << "End year must be a number" unless (@end_year.configuration_value.blank? || @end_year.configuration_value =~ /\A(\d+)\Z/)

    start_int = @start_year.configuration_value.to_i
    end_int = @end_year.configuration_value.to_i
    errors << "End year must be equal to or after start year" if (errors.empty? && (end_int < start_int))

    if errors.empty?
      @start_year.save!
      @end_year.save!
    end
    errors
  end

  def load_values
    @start_year = ConfigurationItem.find_by_name!(ConfigurationItem::YEAR_OF_REGISTRATION_START)
    @end_year = ConfigurationItem.find_by_name!(ConfigurationItem::YEAR_OF_REGISTRATION_END)
  end


end
