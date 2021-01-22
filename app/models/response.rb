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

class Response < ApplicationRecord

  STATUS_UNSUBMITTED = 'Unsubmitted'
  STATUS_SUBMITTED = 'Submitted'

  COMPLETE = 'Complete'
  INCOMPLETE = 'Incomplete'
  COMPLETE_WITH_WARNINGS = 'Complete with warnings'

  CYCLE_ID_MAX_SIZE = 20

  belongs_to :user
  belongs_to :clinic
  belongs_to :batch_file
  belongs_to :survey

  has_many :answers, dependent: :destroy

  validates_presence_of :cycle_id
  # Cycle ID max size to allow length of concatenated CycleID_SiteCode (including underscore character)
  validates_length_of :cycle_id, :minimum => 1, :maximum => CYCLE_ID_MAX_SIZE + Clinic::SITE_CODE_MAX_SIZE + 1
  validates_presence_of :user
  validates_presence_of :survey_id
  validates_presence_of :clinic_id
  # ToDo: refactor year_of_registration to year_of_treatment to keep code consistent with intent
  validates_presence_of :year_of_registration
  validates_inclusion_of :submitted_status, in: [STATUS_UNSUBMITTED, STATUS_SUBMITTED]
  validates_uniqueness_of :cycle_id, scope: [:survey_id, :year_of_registration], case_sensitive: true

  before_validation :strip_whitespace
  before_validation :clear_dummy_answers
  before_save :compute_validation_status
  before_save :clear_dummy_answers

  scope :for_survey, lambda { |survey| where(survey_id: survey.id) }

  scope :unsubmitted, -> {where(submitted_status: STATUS_UNSUBMITTED)}
  scope :submitted, -> {where(submitted_status: STATUS_SUBMITTED)}

  after_initialize { @dummy_answers = [] }


  # Performance Optimisation: we don't load through the association, instead we do a global lookup by ID
  # to a cached set of surveys that are loaded once in an initializer
  def survey
    #SURVEYS[survey_id]
    return Survey.find(self.survey_id) if Rails.env.test?
    Rails.cache.fetch("#{self.survey_id}_SURVEY", compress:false) do
      logger.debug("Fetching [#{self.survey_id}_SURVEY]")
      Survey.includes(sections: [questions: [:cross_question_validations, :question_options]]).find(self.survey_id)
    end
  end
  #Note:Because above, don't retrieve survey_configuration via association, get it the otherway around like SurveyConfiguration.find_by(survey:suvery_1)
  #TODO above code can be removed, because optiomisation should be done in a more rails frendly place
  #i.e split up the Question table and leave out the wide fields to a secondary table

  # as above
  #def survey=(survey)
    #self.survey_id = survey.id
  #end
  ##REMOVE_ABOVE

  def self.for_survey_clinic_and_year_of_registration(survey, unit_code, site_code, year_of_registration)
    results = submitted.for_survey(survey).order(:cycle_id)
    unless unit_code.blank?
      if site_code.blank?
        #results = results.joins(:clinic).where(:clinics => {unit_code: unit_code})
        results = results.where(clinic_id: Clinic.where(capturesystem_id: survey.capturesystems.first.id, unit_code: unit_code).ids)
      else
        #results = results.joins(:clinic).where(:clinics => {unit_code: unit_code, site_code: site_code})
        results = results.where(clinic_id: Clinic.where(capturesystem_id: survey.capturesystems.first.id, unit_code: unit_code, site_code: site_code).ids)
      end
    end
    results = results.where(year_of_registration: year_of_registration) unless year_of_registration.blank?
    #results.includes([:clinic, :answers])
    results
  end

  def self.count_per_survey_and_year_of_registration_and_clinic(survey_id, year, clinic_id)
    if clinic_id.blank?
      responses = Response.where(year_of_registration: year, survey_id: survey_id)
    else
      responses = Response.where(year_of_registration: year, survey_id: survey_id, clinic_id: clinic_id)
    end
    responses.count
  end

  def self.delete_by_survey_and_year_of_registration_and_clinic(survey_id, year, clinic_id)
    if clinic_id.blank?
      Response.destroy_all(["year_of_registration = ? AND survey_id = ?", year, survey_id])
    else
      Response.destroy_all(["year_of_registration = ? AND survey_id = ? AND clinic_id = ?", year, survey_id, clinic_id])
    end
  end

  def self.years_associated_with_survey(survey_id)
    select("distinct year_of_registration").collect(&:year_of_registration).sort
  end

  def self.existing_years_of_registration(capturesystem)
    select("distinct year_of_registration").where(survey: capturesystem.surveys).collect(&:year_of_registration).sort
  end

  def submit!
    if ![COMPLETE, COMPLETE_WITH_WARNINGS].include?(validation_status)
      raise "Can't submit with status #{validation_status}"
    end
    self.submitted_status = STATUS_SUBMITTED
    self.save!
  end

  def submit_warning
    # This method is role-ignorant.
    # Use cancan to check if a response is not submittable before trying to display this
    case validation_status
      when INCOMPLETE
        "This data entry form is incomplete and can't be submitted."
      when COMPLETE_WITH_WARNINGS
        "This data entry form has warnings. Double check them. If you believe them to be correct, contact an administrator."
      else
        nil
    end
  end

  def prepare_answers_to_section_with_blanks_created(section)
    existing_answers = answers_to_section(section).each_with_object({}) { |answer, hash| hash[answer.question_id] = answer }
    section.questions.each do |question|
      #if there's no answer object already, build an empty one
      if !existing_answers.include?(question.id)
        #answer = self.answers.build(question_id: question)
        answer = self.answers.build(question_id: question.id)
        answer.response=self
        existing_answers[question.id] = answer
        @dummy_answers << answer
      end
    end
    existing_answers
  end

  def sections_to_answers_with_blanks_created
    survey.sections.reduce({}) do |hsh, section|
      answers = prepare_answers_to_section_with_blanks_created(section).values
      sorted_answers = answers.sort_by { |a| a.question.question_order }
      hsh.merge section => sorted_answers
    end
  end

  def all_answers_with_blanks_created
    sections_to_answers_with_blanks_created.values.flatten
  end

  def section_started?(section)
    !answers_to_section(section).empty?
  end

  def status_of_section(section)
    answers_to_sec = prepare_answers_to_section_with_blanks_created(section).values

    any_mandatory_question_unanswered = answers_to_sec.any? { |a| a.violates_mandatory }
    any_warnings = answers_to_sec.any? { |a| a.warnings(SurveyConfiguration.find_by(survey: self.survey)).present? }
    any_fatal_warnings = answers_to_sec.any? { |a| a.fatal_warnings.present? }

    if any_fatal_warnings or any_mandatory_question_unanswered
      INCOMPLETE
    elsif any_warnings
      COMPLETE_WITH_WARNINGS
    else
      COMPLETE
    end
  end

  def missing_mandatory_questions
    answers = all_answers_with_blanks_created.select { |a| a.violates_mandatory }
    answers.map(&:question)
  end

  def build_answers_from_hash(hash)
    hash.each do |question_code, answer_text|
      cleaned_text = answer_text.nil? ? "" : answer_text.strip
      question = survey.question_with_code(question_code)
      if question && !cleaned_text.blank?
        answer = answers.build(question_id: question.id, response: self)
        answer.answer_value = cleaned_text
      end
    end
  end

  def fatal_warnings?
    all_answers_with_blanks_created.any? do |answer|
      answer.violates_mandatory || answer.fatal_warnings.present?
    end
  end

  def warnings?(survey_configuration=nil)
    survey_configuration = SurveyConfiguration.find_by(survey: self.survey) if survey_configuration.nil?
    all_answers_with_blanks_created.any? do |answer|
      answer.has_warning?(survey_configuration)
    end || fatal_warnings?
  end

  #TODO: test me
  def get_answer_to(question_id)
    # this filter through the answer object rather than using find, as we want to use it when we haven't yet saved the objects - DON'T CHANGE THIS BEHAVIOUR
    answers.find { |a| a.question_id == question_id }
  end

  #TODO: test me
  def comparable_answer_or_nil_for_question_with_code(question_code)
    question = survey.question_with_code(question_code)
    raise "No question with code #{question_code}" unless question
    answer = get_answer_to(question.id)
    return nil unless answer
    answer.comparable_answer
  end

  private

  def compute_validation_status
    # don't recompute if we're already submitted, as the process is slow, and once submitted the validations can't change
    return if self.submitted_status == STATUS_SUBMITTED

    section_stati = survey.sections.map { |s| status_of_section(s) }

    if section_stati.include? INCOMPLETE
      self.validation_status = INCOMPLETE
    elsif section_stati.include? COMPLETE_WITH_WARNINGS
      self.validation_status = COMPLETE_WITH_WARNINGS
    else
      self.validation_status = COMPLETE
    end
  end

  def answers_to_section(section)
    answers.select {|a| a.question.section_id == section.id}
    #answers.where(question: section.questions)
  end

  def strip_whitespace
    self.cycle_id = self.cycle_id.strip unless self.cycle_id.nil?
  end

  def clear_dummy_answers
    self.answers.delete(self.answers.select{|elem| @dummy_answers.map(&:object_id).include? elem.object_id})
    @dummy_answers.clear
  end

end
