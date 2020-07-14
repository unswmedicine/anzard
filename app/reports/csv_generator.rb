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
#TODO this class needs cleanup !
class CsvGenerator

  #BASIC_HEADERS = %w(TREATMENT_DATA YEAR_OF_TREATMENT ANZARD_Unit_Name ART_Unit_Name CYCLE_ID)
  #attr_accessor :survey_id, :unit_code, :year_of_registration, :records, :survey, :question_codes, :site_code, :prepend_columns
  attr_accessor :survey_id, :unit_code, :year_of_registration, :survey, :question_codes, :site_code, :prepend_columns

  def initialize(the_survey, unit_code, site_code, year_of_registration, prepend_columns)
    self.survey_id = the_survey.id
    self.unit_code = unit_code
    self.site_code = site_code
    self.year_of_registration = year_of_registration
    self.prepend_columns = prepend_columns

    self.survey = the_survey
    self.question_codes = survey.ordered_questions.collect(&:code)

    #self.records = Response.for_survey_clinic_and_year_of_registration(survey, unit_code, site_code, year_of_registration)
  end

  def csv_filename
    name_parts = [survey.name.parameterize(separator: '_')]

    unless unit_code.blank?
      if site_code.blank?
        #currently a survey can only be used in one capture system hence get the `first`
        clinic = Clinic.find_by(capturesystem_id: self.survey.capturesystems.first.id, unit_code: unit_code)
        name_parts << clinic.unit_name.parameterize(separator: '_')
      else
        clinic = Clinic.find_by(capturesystem_id: self.survey.capturesystems.first.id, unit_code: unit_code, site_code: site_code)
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
    #records.empty?
    !Response.for_survey_clinic_and_year_of_registration(survey, unit_code, site_code, year_of_registration).exists?
  end

  def csv
    self.csv_enumerator.to_a.join('')
  end

  def csv_enumerator(batch_size=50)
    Enumerator.new do |yielder|
      report_indexes = []
      report_headers = []
      (prepend_columns + question_codes).each_with_index do |each_header, index|
        if report_headers.include? each_header
          report_indexes.append(index)
        else
          report_headers.append(each_header)
        end
      end
      yielder << CSV.generate_line(report_headers)

      row_count = 0
      start = Time.now
      ordered_reponse_ids = Response.for_survey_clinic_and_year_of_registration(self.survey, self.unit_code, self.site_code, self.year_of_registration).pluck(:id)
      Rails.logger.info(
        "Starting download [#{ordered_reponse_ids.count}] responses for survey:[#{self.survey.name}], unit_code:[#{self.unit_code}], site_code:[#{self.site_code}], year_of_registration:[#{self.year_of_registration}] took #{Time.now - start}"
      )

      ordered_reponse_ids.in_groups_of(batch_size, false).each do |r_ids|
        Response.order(:cycle_id).includes([:clinic]).where(id: r_ids).each do |response|
          row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id] + answers(response)
          report_indexes.reverse.each { |x| row_data.delete_at(x) }
          yielder << CSV.generate_line(row_data)
          row_count += 1
        end
        GC.start if row_count%1000 == 0
      end

      GC.start
      Rails.logger.info(
        "Downloading [#{row_count}] responses for survey:[#{self.survey.name}], unit_code:[#{self.unit_code}], site_code:[#{self.site_code}], year_of_registration:[#{self.year_of_registration}] took #{Time.now - start}"
      )
    end
  end



  private

  def answers(response)
    # Performance optimisation: only select the columns we need - speeds up by 20x
    # instead of this
    # answer_array = response.answers
    # do this (avoiding loading raw_answer saves most of the time)
    #answer_array = response.answers.select([:question_id, :choice_answer, :date_answer, :decimal_answer, :integer_answer, :text_answer, :time_answer])
    #REMOVE_ABOVE
    #answer_array = response.answers 
    #optimised in 'Response.for_survey_clinic_and_year_of_registration'
    #answer_hash = answer_array.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }

    answer_hash = Question.joins(:answers).where(answers:{response_id:response.id}).pluck(
      :'questions.code', :'questions.question_type', "CASE WHEN questions.question_type='Choice' THEN answers.choice_answer WHEN questions.question_type='Date' THEN answers.date_answer WHEN questions.question_type='Decimal' THEN answers.decimal_answer WHEN questions.question_type='Integer' THEN answers.integer_answer WHEN questions.question_type='Text' THEN answers.text_answer WHEN questions.question_type='Time' THEN answers.time_answer ELSE '' END"
    ).map{|a| [ a.slice(0), a.slice(1,2) ]}.to_h
    question_codes.collect do |code|
      CsvGenerator.format_for_csv(answer_hash[code])
    end
  end

  #According to Answer::format_for_csv and Answer::sanitise_and_write_input 
  def self.format_for_csv(q_a)
    return '' if q_a.nil?
    case q_a[0]
      when Answer::TYPE_TEXT, Answer::TYPE_CHOICE
        q_a[1].to_s
      when Answer::TYPE_DECIMAL
        q_a[1].to_f.to_s
      when Answer::TYPE_INTEGER 
        q_a[1].to_i.to_s
      when Answer::TYPE_DATE
        Date.strptime(q_a[1], "%Y-%m-%d").try(:strftime, '%Y-%m-%d') || ''
      when Answer::TYPE_TIME
        Time.strptime(q_a[1], "%H:%M").try(:strftime, '%H:%M') || ''
      else
        raise "Unknown question type #{q_a[0]}"
    end
  end

end
