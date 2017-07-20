require 'csv'
class CsvGenerator

  BASIC_HEADERS = %w(TreatmentData YearOfTreatment UnitName SiteName UnitID SiteID CYCLE_ID)
  attr_accessor :survey_id, :unit_code, :year_of_registration, :records, :survey, :question_codes, :site_code

  def initialize(survey_id, unit_code, year_of_registration, site_code)
    self.survey_id = survey_id
    self.unit_code = unit_code
    self.site_code = site_code
    self.year_of_registration = year_of_registration

    self.survey = SURVEYS[survey_id.to_i]
    self.question_codes = survey.ordered_questions.collect(&:code)

    self.records = Response.for_survey_clinic_and_year_of_registration(survey, unit_code, year_of_registration, site_code)
  end

  def csv_filename
    name_parts = [survey.name.parameterize(separator: '_')]

    unless unit_code.blank?
      clinic = Clinic.find_by_unit_code(unit_code)
      name_parts << clinic.unit_name.parameterize(separator: '_')
      unless clinic.site_name.blank?
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
      csv.add_row BASIC_HEADERS + question_codes
      records.each do |response|
        basic_row_data = [response.survey.name, response.year_of_registration, response.clinic.unit_name, response.clinic.site_name, response.clinic.unit_code, response.clinic.site_code, response.cycle_id]
        csv.add_row basic_row_data + answers(response)
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
