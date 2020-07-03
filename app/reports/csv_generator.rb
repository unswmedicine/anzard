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
    CSV.generate(:col_sep => ",") do |csv|
      report_indexes = []
      report_headers = []
      (prepend_columns + question_codes).each_with_index do |each_header, index|
        if report_headers.include? each_header
          report_indexes.append(index)
        else
          report_headers.append(each_header)
        end
      end

      # csv.add_row prepend_columns + question_codes
      csv.add_row report_headers

      #records.each do |response|
      # basic_row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id]
      #  row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id] + answers(response)
      #  report_indexes.reverse.each { |x| row_data.delete_at(x) }

      # csv.add_row basic_row_data + answers(response)
      #  csv.add_row row_data
      #end
      data_rows = []
      Response.for_survey_clinic_and_year_of_registration(survey, unit_code, site_code, year_of_registration).find_each(batch_size: 100) do |response|
        row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id] + answers(response)
        report_indexes.reverse.each { |x| row_data.delete_at(x) }
        #TODO cleanup the above change merged from anzard3.0
        data_rows << row_data
      end

      #sorting by cycle_id to retain current behavior, assuming cycle_id is at idx=4
      data_rows.sort_by! { |r| r[4] }
      until data_rows.empty?
        csv.add_row(data_rows.shift)
      end
      GC.start

    end
  end

  def csv_enumerator(oder_by_cycle_id = true, batch_size = 50)
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

      sql = "SELECT r.id as response_id, s.name as treatment_data, r.year_of_registration as year_of_treatment,
             c.unit_name as anzard_unit_name, c.site_name as art_unit_name, r.cycle_id as cycle_id,
             q.code as question_code,
             (SELECT COALESCE(
                 (SELECT COALESCE(
                      a.text_answer, a.date_answer, a.time_answer, a.decimal_answer, a.integer_answer, a.choice_answer, a.raw_answer,' ')
                     FROM answers a
                     WHERE a.response_id = r.id AND a.question_id = q.id), ' ')
             ) AS answer
            FROM surveys s
            LEFT JOIN  responses r on r.survey_id = s.id
            LEFT JOIN  clinics c on r.clinic_id = c.id
            LEFT JOIN  sections sec on sec.survey_id = s.id
            LEFT JOIN  questions q on q.section_id = sec.id
            WHERE r.submitted_status='Submitted' and s.id = #{ActiveRecord::Base.sanitize(survey_id)}"


      if unit_code != ""
        sql += " and c.unit_code=#{ActiveRecord::Base.sanitize(unit_code)}"
        if site_code != ""
          sql += " and c.site_code=#{ActiveRecord::Base.sanitize(site_code)}"
        end
      end

      if year_of_registration != ""
        sql += " and r.year_of_registration=#{ActiveRecord::Base.sanitize(year_of_registration)}"
      end
      if oder_by_cycle_id
        sql += " ORDER BY cycle_id, r.id, sec.section_order, q.question_order;"
      else
        sql += " ORDER BY  r.id, sec.section_order, q.question_order;"
      end

      results = ActiveRecord::Base.connection.exec_query(sql)
      puts "Break here"

      response_id = ""
      csv_row = []

      for each_row in results.rows
        if each_row[0] != response_id
          response_id = each_row[0]
          if csv_row != []
            yielder << CSV.generate_line(csv_row)
            csv_row = []
          end
          csv_row << each_row[1]
          csv_row << each_row[2]
          csv_row << each_row[3]
          csv_row << each_row[4]
          csv_row << each_row[5]
        end
        csv_row << each_row[7]
      end
      if csv_row != []
        yielder << CSV.generate_line(csv_row)
      end
      GC.start
      # Response.for_survey_clinic_and_year_of_registration(survey, unit_code, site_code, year_of_registration).find_each(batch_size: batch_size) do |response|
      #   # row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id] + answers(response)
      #   row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.cycle_id] + answers(response)
      #   report_indexes.reverse.each { |x| row_data.delete_at(x) }
      #   csv_rows << row_data
      #   row_count += 1
      #   GC.start if row_count%batch_size == 0
      # end
      # #sorting by cycle_id to retain current behavior, assuming cycle_id is at idx=4
      # csv_rows.sort_by! { |r| r[4] }


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
    answer_array = response.answers
    #optimised in 'Response.for_survey_clinic_and_year_of_registration'
    answer_hash = answer_array.reduce({}) { |hash, answer| hash[answer.question_download.code] = answer; hash }
    question_codes.collect do |code|
      answer = answer_hash[code]
      puts "Answer: "
      puts answer ? answer.format_for_csv : ''
      answer ? answer.format_for_csv : ''
    end

  end

  def custom_download(the_survey, unit_code, site_code, year_of_registration, prepend_columns)
    self.survey_id = the_survey.id
    self.unit_code = unit_code
    self.site_code = site_code
    self.year_of_registration = year_of_registration
    self.prepend_columns = prepend_columns

    self.survey = the_survey
    self.question_codes = survey.ordered_questions.collect(&:code)

  end


end
