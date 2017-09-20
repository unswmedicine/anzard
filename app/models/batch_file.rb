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

class BatchFile < ApplicationRecord

  CYCLE_ID_COLUMN = 'CYCLE_ID'
  UNIT_CODE_COLUMN = 'UNIT'
  SITE_CODE_COLUMN = 'SITE'
  STATUS_FAILED = 'Failed'
  STATUS_SUCCESS = 'Processed Successfully'
  STATUS_REVIEW = 'Needs Review'
  STATUS_IN_PROGRESS = 'In Progress'

  MESSAGE_WARNINGS = 'The file you uploaded has one or more warnings. Please review the reports for details.'
  MESSAGE_NO_CYCLE_ID = "The file you uploaded did not contain a #{CYCLE_ID_COLUMN} column."
  MESSAGE_UNKNOWN_UNIT_SITE = "The file you uploaded contains a #{UNIT_CODE_COLUMN} or #{SITE_CODE_COLUMN} that is unknown to our database."
  MESSAGE_UNAUTHORISED_UNIT_SITE = 'The file you uploaded contains a Unit_Site that you are not allocated to.'
  MESSAGE_MISSING_CYCLE_IDS = 'The file you uploaded is missing one or more cycle IDs. Each record must have a cycle ID.'
  MESSAGE_EMPTY = 'The file you uploaded did not contain any data.'
  MESSAGE_FAILED_VALIDATION = 'The file you uploaded did not pass validation. Please review the reports for details.'
  MESSAGE_SUCCESS = 'Your file has been processed successfully.'
  MESSAGE_BAD_FORMAT = 'The file you uploaded was not a valid CSV file.'
  MESSAGE_DUPLICATE_CYCLE_IDS = 'The file you uploaded contained duplicate cycle IDs. Each cycle ID can only be used once.'
  MESSAGE_UNEXPECTED_ERROR = 'Processing failed due to an unexpected error.'
  MESSAGE_CSV_STOP_LINE = ' Processing stopped on CSV row '
  MESSAGE_NOT_UNIQUE = 'The file you uploaded contained duplicate columns. Each column heading must be unique.'

  belongs_to :user
  belongs_to :clinic
  # ToDo: remove lingering ANZNN supplementary files
  has_many :supplementary_files

  has_attached_file :file, :styles => {}, :path => :make_file_path
  do_not_validate_attachment_file_type :file

  before_validation :set_status
  before_destroy :delete_data_file_and_reports

  validates_presence_of :survey_id
  validates_presence_of :user_id
  validates_presence_of :clinic_id
  validates_presence_of :file_file_name
  validates_presence_of :year_of_registration

  attr_accessor :responses

  scope :failed, -> {where(:status => STATUS_FAILED)}
  scope :older_than, lambda { |date| where('updated_at < ?', date) }

  # Performance Optimisation: we don't load through the association, instead we do a global lookup by ID
  # to a cached set of surveys that are loaded once in an initializer
  def survey
    SURVEYS[survey_id]
  end

  # as above
  def survey=(survey)
    self.survey_id = survey.id
  end

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

  def problem_record_count
    return nil if responses.nil?
    responses.collect { |r| r.warnings? || !r.valid? }.count(true)
  end

  def organised_problems
    organiser = QuestionProblemsOrganiser.new

    # get all the problems from all the responses organised for reporting
    responses.each do |r|
      r.answers.each do |answer|
        organiser.add_problems(answer.question.code, r.cycle_id, answer.fatal_warnings, answer.warnings, answer.format_for_csv)
      end
      r.missing_mandatory_questions.each do |question|
        organiser.add_problems(question.code, r.cycle_id, ['This question is mandatory'], [], '')
      end
      r.valid? #we have to call this to trigger errors getting populated
      organiser.add_problems(CYCLE_ID_COLUMN, r.cycle_id, r.errors.full_messages, [], r.cycle_id) unless r.errors.empty?
    end
    organiser
  end

  private

  def delete_data_file_and_reports
    file.destroy
    File.delete(self.summary_report_path)
    File.delete(self.detail_report_path)
  end

  def process_batch(force)
    logger.info("Processing batch file with id #{id}")
    start = Time.now

    passed_pre_processing = pre_process_file
    unless passed_pre_processing
      save!
      return
    end
    logger.info("After pre-processing took #{Time.now - start}")

    @csv_row_count = 0
    failures = false
    warnings = false
    responses = []
    CSV.foreach(file.path, {headers: true}) do |row|
      @csv_row_count += 1
      cycle_id = row[CYCLE_ID_COLUMN]
      cycle_id.strip! unless cycle_id.nil?
      clinic_in_row = Clinic.find_by(unit_code: row[UNIT_CODE_COLUMN], site_code: row[SITE_CODE_COLUMN])
      response = Response.new(survey: survey, cycle_id: cycle_id, user: user, clinic: clinic_in_row, year_of_registration: year_of_registration, submitted_status: Response::STATUS_UNSUBMITTED, batch_file: self)
      response.build_answers_from_hash(row.to_hash)
      add_answers_from_supplementary_files(response, cycle_id)

      failures = true if (response.fatal_warnings? || !response.valid?)
      warnings = true if response.warnings?
      responses << response
    end
    logger.info("After CSV processing took #{Time.now - start}")

    self.record_count = @csv_row_count
    @csv_row_count = nil
    if failures
      set_outcome(STATUS_FAILED, MESSAGE_FAILED_VALIDATION)
    elsif warnings and !force
      set_outcome(STATUS_REVIEW, MESSAGE_WARNINGS)
    else
      responses.each do |r|
        r.submitted_status = Response::STATUS_SUBMITTED
        r.save!
      end
      set_outcome(STATUS_SUCCESS, MESSAGE_SUCCESS)
    end
    save!
    self.responses = responses #this is only ever kept in memory for the sake of reporting, its not an AR association.
    logger.info("After rest took #{Time.now - start}")

    true
  end

  def add_answers_from_supplementary_files(response, cycle_id)
    supplementary_files.each do |supp_file|
      answers = supp_file.as_denormalised_hash[cycle_id]
      response.build_answers_from_hash(answers) if answers
    end
  end

  def pre_process_file
    # do basic checks that can result in the file failing completely and not being validated
    @csv_row_count = 0

    # ToDo: update so that headers and survey question codes are downcased and stripped of trailing whitespace
    headers = CSV.read(file.path, {headers: true}).headers
    survey_question_codes = survey.questions.pluck(:code)
    unless headers.sort == survey_question_codes.sort
      # ToDo: figure out which question headers are missing and display that to the user
      set_outcome(STATUS_FAILED, 'The file you uploaded is missing some question headers.' + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
      return false
    end


    cycle_ids = []
    CSV.foreach(file.path, {headers: true}) do |row|
      unless row.headers.include?(CYCLE_ID_COLUMN)
        set_outcome(STATUS_FAILED, MESSAGE_NO_CYCLE_ID + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
        return false
      end
      unless headers_unique?(row.headers)
        set_outcome(STATUS_FAILED, MESSAGE_NOT_UNIQUE)
        return false
      end
      @csv_row_count += 1
      cycle_id = row[CYCLE_ID_COLUMN]
      if cycle_id.blank?
        set_outcome(STATUS_FAILED, MESSAGE_MISSING_CYCLE_IDS + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
        return false
      else
        cycle_id.strip!
        if cycle_ids.include?(cycle_id)
          set_outcome(STATUS_FAILED, MESSAGE_DUPLICATE_CYCLE_IDS + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
          return false
        else
          cycle_ids << cycle_id
        end
      end

      clinic_in_row = Clinic.find_by(unit_code: row[UNIT_CODE_COLUMN], site_code: row[SITE_CODE_COLUMN])
      if clinic_in_row.nil?
        set_outcome(STATUS_FAILED, MESSAGE_UNKNOWN_UNIT_SITE + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
        return false
      else
        unless user.clinics.exists? clinic_in_row.id
          set_outcome(STATUS_FAILED, MESSAGE_UNAUTHORISED_UNIT_SITE + MESSAGE_CSV_STOP_LINE + @csv_row_count.to_s)
          return false
        end
      end
    end

    if @csv_row_count == 0
      set_outcome(STATUS_FAILED, MESSAGE_EMPTY)
      return false
    end

    @csv_row_count = nil

    supplementary_files.each do |supplementary_file|
      unless supplementary_file.pre_process
        set_outcome(STATUS_FAILED, supplementary_file.message)
        return false
      end
    end

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
