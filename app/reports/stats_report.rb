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

class StatsReport

  attr_accessor :survey, :counts, :years

  def initialize(survey)
    self.survey = survey
    self.counts = Response.where(survey_id: survey.id).group(:year_of_registration, :submitted_status, :clinic_id).count
    self.years = Response.for_survey(survey).select("distinct year_of_registration").collect(&:year_of_registration).sort
  end

  def response_count(year_of_registration, submitted_status, clinic_id)
    # counts will be a hash with keys: [year_of_reg, submitted_status, clinic_id], values: the count
    counts[[year_of_registration, submitted_status, clinic_id]] || "none"
  end

  def empty?
    Response.for_survey(survey).count == 0
  end
end