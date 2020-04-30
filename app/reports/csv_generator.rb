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

require 'csv'
class CsvGenerator

  BASIC_HEADERS = %w(TREATMENT_DATA YEAR_OF_TREATMENT ANZARD_Unit_Name ART_Unit_Name CYCLE_ID)
  attr_accessor :survey_id, :unit_code, :year_of_registration, :records, :survey, :question_codes, :site_code

  def initialize(survey_id, unit_code, site_code, year_of_registration)
    self.survey_id = survey_id
    self.unit_code = unit_code
    self.site_code = site_code
    self.year_of_registration = year_of_registration

    self.survey = SURVEYS[survey_id.to_i]
    self.question_codes = survey.ordered_questions.collect(&:code)

    self.records = Response.for_survey_clinic_and_year_of_registration(survey, unit_code, site_code, year_of_registration)
  end

  def csv_filename
    name_parts = [survey.name.parameterize(separator: '_')]

    unless unit_code.blank?
      if site_code.blank?
        clinic = Clinic.find_by(unit_code: unit_code)
        name_parts << clinic.unit_name.parameterize(separator: '_')
      else
        clinic = Clinic.find_by(unit_code: unit_code, site_code: site_code)
        name_parts << clinic.unit_name.parameterize(separator: '_')
        name_parts << clinic.site_name.parameterize(separator: '_')
      end
    end
    
    unless year_of_registration.blank?
      name_parts << year_of_registration
    end
    name_parts.join("_") + ".csv"
  end

  def empty?
    records.empty?
  end

  def csv
    CSV.generate(:col_sep => ",") do |csv|
      report_indexes = []
      report_headers = []
      (BASIC_HEADERS + question_codes).each_with_index do |each_header, index|
        if report_headers.include? each_header
          report_indexes.append(index)
        else
          report_headers.append(each_header)
        end
      end

      # csv.add_row BASIC_HEADERS + question_codes
      csv.add_row report_headers
      records.each do |response|
        # basic_row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id]
        row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id] + answers(response)
        report_indexes.reverse.each { |x| row_data.delete_at(x) }

        # csv.add_row basic_row_data + answers(response)
        csv.add_row row_data
      end
    end
  end

  private

  def answers(response)
    # Performance optimisation: only select the columns we need - speeds up by 20x
    # instead of this
    # answer_array = response.answers
    # do this (avoiding loading raw_answer saves most of the time)
    answer_array = response.answers.select([:question_id, :choice_answer, :date_answer, :decimal_answer, :integer_answer, :text_answer, :time_answer])
    answer_hash = answer_array.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
    question_codes.collect do |code|
      answer = answer_hash[code]
      answer ? answer.format_for_csv : ''
    end
  end

end
