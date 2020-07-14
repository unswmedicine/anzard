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
#TODO this class needs cleanup
class BatchFile < ApplicationRecord

  STATUS_FAILED = 'Failed'
  STATUS_SUCCESS = 'Processed Successfully'
  STATUS_REVIEW = 'Needs Review'
  STATUS_IN_PROGRESS = 'In Progress'

  COLUMN_CYCLE_ID = 'CYCLE_ID'
  COLUMN_CYCLE_ID_DOWNCASE = 'cycle_id'
  COLUMN_UNIT_CODE = 'UNIT'
  COLUMN_UNIT_CODE_DOWNCASE = 'unit'
  COLUMN_SITE_CODE = 'SITE'
  COLUMN_SITE_CODE_DOWNCASE = 'site'
  COLUMN_ANZARD_UNIT_CODE = 'ANZARD_UNIT'
  COLUMN_ART_UNIT_SITE_CODE = 'ART_UNIT'
  COLUMN_ART_UNIT_SITE_CODE_DOWNCASE = 'art_unit'

  MESSAGE_WARNINGS = 'The file you uploaded has one or more warnings. Please review the reports for details.'
  MESSAGE_NO_CYCLE_ID = "The file you uploaded did not contain a #{COLUMN_CYCLE_ID} column."
  MESSAGE_UNKNOWN_UNIT_SITE = "The file you uploaded contains a #{COLUMN_UNIT_CODE}/#{COLUMN_ANZARD_UNIT_CODE} or #{COLUMN_SITE_CODE}/#{COLUMN_ART_UNIT_SITE_CODE} that is unknown to our database."
  
  MESSAGE_UNAUTHORISED_UNIT_SITE = 'The file you uploaded contains a ART_UNIT that you are not allocated to.'
  MESSAGE_MISSING_CYCLE_IDS = 'The file you uploaded is missing one or more cycle IDs. Each record must have a cycle ID.'
  MESSAGE_EMPTY = 'The file you uploaded did not contain any data.'
  MESSAGE_FAILED_VALIDATION = 'The file you uploaded did not pass validation. Please review the reports for details.'
  MESSAGE_SUCCESS = 'Your file has been processed successfully.'
  MESSAGE_BAD_FORMAT = 'The file you uploaded was not a valid CSV file.'
  MESSAGE_DUPLICATE_CYCLE_IDS = 'The file you uploaded contained duplicate cycle IDs. Each cycle ID can only be used once.'
  MESSAGE_UNEXPECTED_ERROR = 'Processing failed due to an unexpected error.'
  MESSAGE_CSV_STOP_LINE = ' Processing stopped on CSV row '
  MESSAGE_NOT_UNIQUE = 'The file you uploaded contained duplicate columns. Each column heading must be unique.'
  MESSAGE_MISSING_HEADER_COLUMNS = 'The file you uploaded is missing the following column(s): '

  belongs_to :user
  belongs_to :clinic

  has_attached_file :file, :styles => {}, :path => :make_file_path
  do_not_validate_attachment_file_type :file

  before_validation :set_status
  before_destroy :delete_data_file_and_reports

  validates_presence_of :survey_id
  validates_presence_of :user_id
  validates_presence_of :clinic_id
  validates_presence_of :file_file_name
  validates_presence_of :year_of_registration

  #attr_accessor :responses
  attr_accessor :organised_problems
  attr_accessor :problem_record_count

  scope :failed, -> {where(:status => STATUS_FAILED)}
  scope :older_than, lambda { |date| where('updated_at < ?', date) }

  # Performance Optimisation: we don't load through the association, instead we do a global lookup by ID
  # to a cached set of surveys that are loaded once in an initializer
  #def survey
    #SURVEYS[survey_id]
  #end
  ##REMOVE_ABOVE

  # as above
  #def survey=(survey)
    #self.survey_id = survey.id
  #end
  ##REMOVE_ABOVE

  belongs_to :survey

  def make_file_path
    # this is a method so that APP_CONFIG has been loaded by the time is executes
    "#{APP_CONFIG['batch_files_root']}/:id.:extension"
  end

  def has_summary_report?
    !summary_report_path.blank?
  end

  def has_detail_report?
    !detail_report_path.blank?
  end

  def success?
    self.status == STATUS_SUCCESS
  end

  def force_submittable?
    status == STATUS_REVIEW
  end

  def process(force=false)
    raise 'Batch has already been processed, cannot reprocess' unless status == STATUS_IN_PROGRESS

    BatchFile.transaction do
      start = Time.now
      begin
        can_generate_report = process_batch(force)
        if can_generate_report && !force
          BatchReportGenerator.new(self).generate_reports
        end
      rescue ArgumentError
        logger.info('Argument error while reading file')
        logger.error("Message: #{$!.message}")
        logger.error $!.backtrace
        # Note: Catching ArgumentError seems a bit odd, but CSV throws it when the file is not UTF-8 which happens if you upload an xls file
        if @csv_row_count.present?
          set_outcome(STATUS_FAILED, MESSAGE_BAD_FORMAT + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
        else
          set_outcome(STATUS_FAILED, MESSAGE_BAD_FORMAT)
        end
      rescue CSV::MalformedCSVError
        logger.info('Malformed CSV error while reading file')
        if @csv_row_count.present?
          set_outcome(STATUS_FAILED, MESSAGE_BAD_FORMAT + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
        else
          set_outcome(STATUS_FAILED, MESSAGE_BAD_FORMAT)
        end
      rescue
        logger.error("Unexpected processing error while reading / processing file: Exception: #{$!.class}, Message: #{$!.message}")
        logger.error $!.backtrace
        if @csv_row_count.present?
          set_outcome(STATUS_FAILED, MESSAGE_UNEXPECTED_ERROR + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
        else
          set_outcome(STATUS_FAILED, MESSAGE_UNEXPECTED_ERROR)
        end
        raise
      end
      save!
      logger.info("Finished processing file with id #{id}, status is now #{status}, processing took #{Time.now - start}")
    end
  end

#  def problem_record_count
#    return nil if responses.nil?
#    survey_configuration = SurveyConfiguration.find_by(survey:self.survey)
#    responses.collect { |r| r.warnings?(survey_configuration) || !r.valid? }.count(true)
#  end

#  def organised_problems
#    survey_configuration = SurveyConfiguration.find_by(survey:self.survey)
#    organiser = QuestionProblemsOrganiser.new
#
#    # get all the problems from all the responses organised for reporting
#    responses.each do |r|
#      # Get original cycle ID (cycle ID without site code) for display in reports to user
#      cycle_id_without_site_code = r.cycle_id
#      concatenated_site_code = '_' + r.clinic.site_code.to_s
#      if r.cycle_id.end_with?(concatenated_site_code)
#        cycle_id_without_site_code = r.cycle_id.slice(0, r.cycle_id.length - concatenated_site_code.length)
#      end
#
#      r.answers.each do |answer|
#        organiser.add_problems(answer.question.code, cycle_id_without_site_code, answer.fatal_warnings, answer.warnings(survey_configuration), answer.format_for_csv)
#      end
#      r.missing_mandatory_questions.each do |question|
#        organiser.add_problems(question.code, cycle_id_without_site_code, ['This question is mandatory'], [], '')
#      end
#
#      r.valid? # we have to call this to trigger errors getting populated
#      unless r.errors.empty?
#        # Replace auto-concatenated cycle ID with original cycle ID for display of record validation errors
#        response_error_msgs = r.errors.full_messages
#        response_error_msgs.each do |msg|
#          msg.gsub!(r.cycle_id, cycle_id_without_site_code)
#        end
#        organiser.add_problems(COLUMN_CYCLE_ID, cycle_id_without_site_code, response_error_msgs, [], cycle_id_without_site_code)
#      end
#    end
#    organiser
#  end

  private

  def delete_data_file_and_reports
    file.destroy
    File.delete(self.summary_report_path) if has_summary_report?
    File.delete(self.detail_report_path) if has_detail_report?
  end

  def process_batch(force)
    logger.info("Processing batch file with id #{id}")
    survey_configuration = SurveyConfiguration.find_by(survey:self.survey)

    start = Time.now
    self.problem_record_count = 0

    passed_pre_processing = pre_process_file
    unless passed_pre_processing
      save!
      return
    end
    logger.info("After pre-processing took #{Time.now - start}")

    @csv_row_count = 0
    failures = false
    warnings = false
    #responses = []
    prepared_responses = []
    response = nil
    self.organised_problems = QuestionProblemsOrganiser.new
    CSV.foreach(file.path, {headers: true, header_converters: lambda {|header| sanitise_question_code(header)}}) do |row|
      @csv_row_count += 1
      cycle_id = row[COLUMN_CYCLE_ID_DOWNCASE]
      cycle_id.strip! unless cycle_id.nil?
      #merged the below fallback behavior from ANZARD3.0 changes
      #clinic_in_row = Clinic.find_by(capturesystem_id: self.clinic.capturesystem.id, unit_code: row[sanitise_question_code(COLUMN_UNIT_CODE)], site_code: row[sanitise_question_code(COLUMN_SITE_CODE)])
      #if clinic_in_row.nil?
      #  #clinic_in_row = Clinic.find_by(capturesystem_id: self.clinic.capturesystem.id, unit_code: row[sanitise_question_code(COLUMN_ANZARD_UNIT_CODE)], site_code: row[sanitise_question_code(COLUMN_ART_UNIT_SITE_CODE)])
      #  clinic_in_row = Clinic.find_by(capturesystem_id: self.clinic.capturesystem.id, unit_code: row[sanitise_question_code("#{self.clinic.capturesystem.name}_#{COLUMN_UNIT_CODE}")], site_code: row[sanitise_question_code(COLUMN_ART_UNIT_SITE_CODE)])
      #end


      #concatenated_cycle_id = cycle_id + '_' + clinic_in_row.site_code.to_s
      #response = Response.new(survey: survey, cycle_id: concatenated_cycle_id, user: user, clinic: clinic_in_row, year_of_registration: year_of_registration, submitted_status: Response::STATUS_UNSUBMITTED, batch_file: self)
      concatenated_cycle_id = cycle_id + '_' + self.clinic.site_code.to_s
      response = Response.new(survey: survey, cycle_id: concatenated_cycle_id, user: user, clinic: self.clinic, year_of_registration: year_of_registration, submitted_status: Response::STATUS_UNSUBMITTED, batch_file: self)
      answers_hash = row.to_hash
      response.build_answers_from_hash(answers_hash)
      prepared_responses << [concatenated_cycle_id, answers_hash]

      failures = true if (response.fatal_warnings? || !response.valid?)
      if (response.warnings?(survey_configuration)|| !response.valid?)
        warnings = true 
        self.problem_record_count += 1
      end
      #responses << response
      self.organised_problems.organise(response, survey_configuration)
    end
    logger.info("After CSV processing took #{Time.now - start}")

    self.record_count = @csv_row_count
    @csv_row_count = nil
    if failures
      set_outcome(STATUS_FAILED, MESSAGE_FAILED_VALIDATION)
    elsif warnings and !force
      set_outcome(STATUS_REVIEW, MESSAGE_WARNINGS)
    else
      #responses.each do |r|
      #  r.submitted_status = Response::STATUS_SUBMITTED
      #  r.save!
      #end

      prepared_responses.each do |r|
        response = Response.new(survey: self.survey, cycle_id: r[0], user: self.user, clinic: self.clinic, year_of_registration: year_of_registration, submitted_status: Response::STATUS_SUBMITTED, batch_file: self)
        response.build_answers_from_hash(r[1])
        response.save!
      end

      set_outcome(STATUS_SUCCESS, MESSAGE_SUCCESS)
    end
    save!
    #self.responses = responses #this is only ever kept in memory for the sake of reporting, its not an AR association.
    logger.info("After rest took #{Time.now - start}")

    true
  end

  def sanitise_question_code(question_code)
    question_code.downcase.strip unless question_code.nil?
  end

  def missing_batch_file_headers(sanitised_batch_headers, sanitised_question_codes)
    missing_headers = []
    unless sanitised_batch_headers.sort == sanitised_question_codes.sort
      sanitised_question_codes.each do |question_code|
        unless sanitised_batch_headers.include?(question_code)
          missing_headers.append(question_code)
        end
      end
    end
    missing_headers
  end

  def pre_process_file
    unless user.clinics.exists? self.clinic.id
      set_outcome(STATUS_FAILED, MESSAGE_UNAUTHORISED_UNIT_SITE)
      return false
    end

    # do basic checks that can result in the file failing completely and not being validated
    cycle_ids = []
    @csv_row_count = 0
    capturesystem_unit_column_name = sanitise_question_code("#{self.clinic.capturesystem.name}_#{COLUMN_UNIT_CODE}")
    CSV.foreach(file.path, {headers: true, return_headers: true,
                            header_converters: lambda {|header| sanitise_question_code(header)}}) do |row|
      if row.header_row?
        survey_question_codes = survey.questions.pluck(:code)
        sanitised_question_codes = survey_question_codes.map{|code| sanitise_question_code(code)}
        missing_batch_headers = missing_batch_file_headers(row.headers, sanitised_question_codes)
        unless missing_batch_headers.empty?
          set_outcome(STATUS_FAILED, MESSAGE_MISSING_HEADER_COLUMNS + survey_question_codes.select{|code| missing_batch_headers.include?(code.downcase)}.join(', '))
          return false
        end
        unless headers_unique?(row.headers)
          set_outcome(STATUS_FAILED, MESSAGE_NOT_UNIQUE)
          return false
        end
      else
        @csv_row_count += 1
        cycle_id = row[COLUMN_CYCLE_ID_DOWNCASE]&.strip
        if cycle_id.blank?
          set_outcome(STATUS_FAILED, MESSAGE_MISSING_CYCLE_IDS + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
          return false
        else
          if cycle_ids.include?(cycle_id)
            set_outcome(STATUS_FAILED, MESSAGE_DUPLICATE_CYCLE_IDS + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
            return false
          else
            cycle_ids << cycle_id
          end
        end

        unless (
          self.clinic.unit_code == row[COLUMN_UNIT_CODE_DOWNCASE].to_i && self.clinic.site_code == row[COLUMN_SITE_CODE_DOWNCASE].to_i ||
          self.clinic.unit_code == row[capturesystem_unit_column_name].to_i && self.clinic.site_code == row[COLUMN_ART_UNIT_SITE_CODE_DOWNCASE].to_i
        )
          message_unknown_unit_site = "The file you uploaded contains a #{COLUMN_UNIT_CODE}/#{self.clinic.capturesystem.name}_#{COLUMN_UNIT_CODE} or #{COLUMN_SITE_CODE}/#{COLUMN_ART_UNIT_SITE_CODE} that is unknown to our database."
          set_outcome(STATUS_FAILED, message_unknown_unit_site + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
          return false
        end
      end
    end

    if @csv_row_count == 0
      set_outcome(STATUS_FAILED, MESSAGE_EMPTY)
      return false
    end

    @csv_row_count = nil

    true
  end

  def set_status
    self.status = STATUS_IN_PROGRESS if self.status.nil?
  end

  def set_outcome(status, message)
    self.status = status
    self.message = message
  end

  def headers_unique?(headers)
    headers.compact.count == headers.compact.uniq.count
  end
end
