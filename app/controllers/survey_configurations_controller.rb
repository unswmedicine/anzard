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

class SurveyConfigurationsController < ApplicationController

  before_action :authenticate_user!
  load_and_authorize_resource
  set_tab :survey_configuration, :admin_navigation

  def index
    # ToDo: order by associated survey name
    @survey_configurations = SurveyConfiguration.accessible_by(current_ability)
  end

  def edit
  end

  def update
    # YEAR_OF_REGISTRATION_START = "YearOfRegStart"
    # YEAR_OF_REGISTRATION_END = "YearOfRegEnd"
    @survey_configuration.start_year_of_treatment = params[:survey_configuration][:start_year_of_treatment]
    @survey_configuration.end_year_of_treatment = params[:survey_configuration][:end_year_of_treatment]
    if @survey_configuration.save
      redirect_to survey_configurations_path, notice: "Survey configuration was successfully updated."
    else
      redirect_to(edit_survey_configuration_path(@survey_configuration), alert: @survey_configuration.errors.full_messages.first)
    end
  end
end