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

class SurveyConfiguration < ApplicationRecord

  YEAR_RANGE_TYPE_CALENDAR = 'C'
  YEAR_RANGE_TYPE_FISCAL = 'F'

  # Survey Configuration used to store survey attributes that require dynamic change since surveys are statically pre-loaded on server start
  belongs_to :survey

  validates :start_year_of_treatment, numericality: {less_than: 2100, greater_than: 1900, only_integer: true}, allow_nil: true
  validates :end_year_of_treatment, numericality: {less_than: 2100, greater_than: 1900, only_integer: true}, allow_nil: true
  validate :both_years_provided
  validate :start_year_before_end_year
  validates :year_range_type, inclusion: { in: [YEAR_RANGE_TYPE_CALENDAR, YEAR_RANGE_TYPE_FISCAL] }

  def start_year_before_end_year
    unless start_year_of_treatment.nil? or end_year_of_treatment.nil?
      errors.add(:start_year_of_treatment, "must be less than or equal to end year of treatment") unless start_year_of_treatment <= end_year_of_treatment
      errors.add(:end_year_of_treatment, "must be greater than or equal to start year of treatment") unless start_year_of_treatment <= end_year_of_treatment
    end
  end

  def both_years_provided
    errors.add(:start_year_of_treatment, "cannot be empty if a value is provided for end year of treatment") if start_year_of_treatment.nil? and !end_year_of_treatment.nil?
    errors.add(:end_year_of_treatment, "cannot be empty if a value is provided for start year of treatment") if end_year_of_treatment.nil? and !start_year_of_treatment.nil?
  end
end