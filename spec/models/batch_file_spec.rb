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

require 'rails_helper'
include CsvSurveyOperations

describe BatchFile do
  let(:capturesystem) { create(:capturesystem) }
  let(:survey) do
    question_file = Rails.root.join 'test_data/survey', 'survey_questions.csv'
    options_file = Rails.root.join 'test_data/survey', 'survey_options.csv'
    cross_question_validations_file = Rails.root.join 'test_data/survey', 'cross_question_validations.csv'
    create_survey("some_name", question_file, options_file, cross_question_validations_file)
  end
  let(:capturesystem_survey) { create(:capturesystem_survey, capturesystem: capturesystem, survey: survey) }
  let(:user) { create(:user) }
  let(:clinic) { create(:clinic, capturesystem: capturesystem, unit_code: 100, site_code: 100) }
  let(:clinic_allocation) { create(:clinic_allocation, user: user, clinic: clinic) }

  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:clinic) }
  end

  describe "Validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:survey_id) }
    it { should validate_presence_of(:clinic_id) }
    it { should validate_presence_of(:year_of_registration) }
  end

  describe "Scopes" do
    describe "Failed" do
      it "should only include failed batches" do
        d1 = create(:batch_file, status: BatchFile::STATUS_FAILED)
        create(:batch_file, status: BatchFile::STATUS_SUCCESS)
        create(:batch_file, status: BatchFile::STATUS_REVIEW)
        create(:batch_file, status: BatchFile::STATUS_IN_PROGRESS)
        d5 = create(:batch_file, status: BatchFile::STATUS_FAILED)
        BatchFile.failed.collect(&:id).sort.should eq([d1.id, d5.id])
      end
    end

    describe "Older than" do
      it "should only return files older than the specified date" do
        time = Time.new(2011, 4, 14, 0, 30)
        d1 = create(:batch_file, updated_at: Time.new(2011, 4, 14, 1, 2))
        d2 = create(:batch_file, updated_at: Time.new(2011, 4, 13, 23, 59))
        d3 = create(:batch_file, updated_at: Time.new(2011, 4, 14, 0, 30))
        d4 = create(:batch_file, updated_at: Time.new(2011, 1, 1, 14, 24))
        d5 = create(:batch_file, updated_at: Time.new(2011, 4, 15, 0, 0))
        d6 = create(:batch_file, updated_at: Time.new(2011, 5, 15, 0, 0))
        BatchFile.older_than(time).collect(&:id).should eq([d2.id, d4.id])
      end
    end
  end

  describe "New object should have status set to 'In Progress'" do
    it "Should set the status on a new object" do
      create(:batch_file).status.should eq("In Progress")
    end

    it "Shouldn't update status if already set" do
      create(:batch_file, status: "Mine").status.should eq("Mine")
    end
  end

  describe "force_submittable?" do
    let(:batch_file) { BatchFile.new }
    it "returns true when NEEDS_REVIEW" do
      batch_file.stub(:status) { BatchFile::STATUS_REVIEW }

      batch_file.should be_force_submittable
    end
    it "returns false for FAILED, SUCCESS, IN_PROGRESS" do
      [BatchFile::STATUS_FAILED, BatchFile::STATUS_SUCCESS, BatchFile::STATUS_IN_PROGRESS].each do |status|
        batch_file.stub(:status) { status }

        batch_file.should_not be_force_submittable
      end
    end
  end

  describe "can't process based on status" do
    let(:batch_file) { BatchFile.new }
    it "should die trying to force successful" do
      [BatchFile::STATUS_FAILED, BatchFile::STATUS_SUCCESS, BatchFile::STATUS_IN_PROGRESS].each do |status|
        batch_file.stub(:status) { status }

        if status == BatchFile::STATUS_IN_PROGRESS
          # Batch process explicitly raises error unless status is in progress. When in progress, this will raise
          #  type error due to no file being attached to the batch file object
          expect { batch_file.process }.to raise_error('no implicit conversion of nil into String')
          expect { batch_file.process(:force) }.to raise_error('no implicit conversion of nil into String')
        else
          expect { batch_file.process }.to raise_error("Batch has already been processed, cannot reprocess")
          expect { batch_file.process(:force) }.to raise_error("Batch has already been processed, cannot reprocess")
        end

      end
    end
    it "should needs_review" do
      batch_file.stub(:status) { BatchFile::STATUS_REVIEW }
      expect { batch_file.process }.to raise_error("Batch has already been processed, cannot reprocess")
    end
  end

  #These are integration tests that verify the file processing works correctly
  describe 'File processing' do
    before :each do
      clinic_allocation
    end

    describe "invalid files" do
      it "should reject binary files such as xls" do
        batch_file = process_batch_file('not_csv.xls', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded was not a valid CSV file. Processing stopped on CSV row 0')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it "should reject files that are text but have malformed csv" do
        batch_file = process_batch_file('invalid_csv.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded was not a valid CSV file. Processing stopped on CSV row 2')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files with one or more blank columns' do
        batch_file = process_batch_file('blank_column.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded was not a valid CSV file. Processing stopped on CSV row 0')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)

        batch_file = process_batch_file('blank_columns.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded was not a valid CSV file. Processing stopped on CSV row 0')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it "should reject file without a cycle id column" do
        batch_file = process_batch_file('no_cycle_id_column.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded is missing the following column(s): CYCLE_ID')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it "should reject files that are empty" do
        # Expect the processing of the empty file to return exception during tests, which is otherwise caught and displayed in the controller.
        # This exception is raised because the PaperClip gem determines that the empty CSV is a spoofing attempt.
        expect {
          batch_file = process_batch_file('empty.csv', survey, user)
          expect_fail_status_with_message(batch_file, 'The file you uploaded did not contain any data.')
          expect_no_records_and_no_problem_records(batch_file)
          expect_no_summary_report_and_no_detail_report(batch_file)
        }.to raise_error ActiveRecord::RecordInvalid, 'Validation failed: File has contents that are not what they are reported to be'
      end

      it "should reject files that have a header row only" do
        batch_file = process_batch_file('headers_only.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded did not contain any data.')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files that do not have all survey questions included in the header row' do
        batch_file = process_batch_file('missing_some_headers.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded is missing the following column(s): TextOptional, Date2, Time2')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files that have a row without a UNIT field' do
        batch_file = process_batch_file('no_unit_code_field.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded contains a UNIT or SITE that is unknown to our database. Processing stopped on CSV row 1')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files that have a row with an unknown Unit Code' do
        batch_file = process_batch_file('unknown_unit_code.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded contains a UNIT or SITE that is unknown to our database. Processing stopped on CSV row 2')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files that have a row without a SITE field' do
        batch_file = process_batch_file('no_site_code_field.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded contains a UNIT or SITE that is unknown to our database. Processing stopped on CSV row 1')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files that have a row with an Unknown Site Code' do
        batch_file = process_batch_file('unknown_site_code.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded contains a UNIT or SITE that is unknown to our database. Processing stopped on CSV row 2')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files that contain a row with a Site Code the user is not allocated to' do
        create(:clinic, capturesystem: capturesystem, unit_code: 100, site_code: 999)
        batch_file = process_batch_file('unauthorised_site_code.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded contains a Unit_Site that you are not allocated to. Processing stopped on CSV row 2')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it 'should reject files that contain a row with a Unit Code the user is not allocated to' do
        create(:clinic, capturesystem: capturesystem, unit_code: 999, site_code: 100)
        batch_file = process_batch_file('unauthorised_unit_code.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded contains a Unit_Site that you are not allocated to. Processing stopped on CSV row 2')
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end
    end

    describe 'well formatted files' do

      describe 'CSV header formatting' do
        def check_batch_file_ok(batch_file, survey, user, clinic)
          expect_successful_status_with_message(batch_file, 'Your file has been processed successfully.')
          response = Response.find_by_cycle_id!("12345_#{batch_file.clinic.site_code}")#updated according to ANZARD-234
          response.survey.should eq(survey)
          response.user.should eq(user)
          response.clinic.should eq(clinic)
          response.submitted_status.should eq(Response::STATUS_SUBMITTED)
          response.batch_file.id.should eq(batch_file.id)
          answer_hash = response.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
          answer_hash['TextMandatory'].text_answer.should == 'Val1'
          answer_hash['TextOptional'].should be_nil #not answered
          answer_hash['Date1'].date_answer.should == Date.parse('2011-12-25')
          answer_hash['Time'].time_answer.should == Time.utc(2000, 1, 1, 14, 30)
          answer_hash['Choice'].choice_answer.should == '0'
          answer_hash['Decimal'].decimal_answer.should == 56.77
          answer_hash['Integer'].integer_answer.should == 10
        end

        it 'should accept files with headers in upper-case' do
          batch_file = process_batch_file('no_errors_or_warnings_headers_upper_case.csv', survey, user)
          check_batch_file_ok(batch_file, survey, user, clinic)
        end

        it 'should accept files with headers in lower-case' do
          batch_file = process_batch_file('no_errors_or_warnings_headers_lower_case.csv', survey, user)
          check_batch_file_ok(batch_file, survey, user, clinic)
        end

        it 'should accept files with headers in mixed-case' do
          batch_file = process_batch_file('no_errors_or_warnings_headers_mixed_case.csv', survey, user)
          check_batch_file_ok(batch_file, survey, user, clinic)
        end

        it 'should accept files with headers containing leading or trailing spaces' do
          batch_file = process_batch_file('no_errors_or_warnings_header_spaces.csv', survey, user)
          check_batch_file_ok(batch_file, survey, user, clinic)
        end
      end

      it "file with no errors or warnings - should create the survey responses and answers" do
        batch_file = process_batch_file('no_errors_or_warnings.csv', survey, user, 2008)
        batch_file.organised_problems.detailed_problems.should eq []
        expect_successful_status_with_message(batch_file, "Your file has been processed successfully.")
        Response.count.should == 3
        Answer.count.should eq(30) #3x12 questions = 36, 6 not answered
        batch_file.problem_record_count.should == 0
        batch_file.record_count.should == 3

        r1 = Response.find_by_cycle_id!("B1_#{batch_file.clinic.site_code}")#updated according to ANZARD-234
        r2 = Response.find_by_cycle_id!("B2_#{batch_file.clinic.site_code}")
        r3 = Response.find_by_cycle_id!("B3_#{batch_file.clinic.site_code}")

        [r1, r2, r3].each do |r|
          r.survey.should eq(survey)
          r.user.should eq(user)
          r.clinic.should eq(clinic)
          r.submitted_status.should eq(Response::STATUS_SUBMITTED)
          r.batch_file.id.should eq(batch_file.id)
          r.year_of_registration.should eq(2008)
        end

        answer_hash = r1.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
        answer_hash["TextMandatory"].text_answer.should == "B1Val1"
        answer_hash["TextOptional"].should be_nil #not answered
        answer_hash["Date1"].date_answer.should == Date.parse("2011-12-25")
        answer_hash["Time"].time_answer.should == Time.utc(2000, 1, 1, 14, 30)
        answer_hash["Choice"].choice_answer.should == "0"
        answer_hash["Decimal"].decimal_answer.should == 56.77
        answer_hash["Integer"].integer_answer.should == 10
        Answer.all.each { |a| a.has_fatal_warning?.should be false }
        Answer.all.each { |a| a.has_warning?.should be false }
        batch_file.record_count.should == 3
                                   # summary report should exist but not detail report
        batch_file.summary_report_path.should_not be_nil
        File.exist?(batch_file.summary_report_path).should be true
        batch_file.detail_report_path.should be_nil
      end

      it "file with no errors or warnings - should create the survey responses and answers and should strip leading/trailing whitespace" do
        batch_file = process_batch_file('no_errors_or_warnings_whitespace.csv', survey, user)
        expect_successful_status_with_message(batch_file, "Your file has been processed successfully.")
        Response.count.should == 3
        Answer.count.should eq(30) #3x12 questions = 36, 6 not answered
        batch_file.problem_record_count.should == 0
        batch_file.record_count.should == 3

        r1 = Response.find_by_cycle_id!("B1_#{batch_file.clinic.site_code}")#updated according to ANZARD-234
        r2 = Response.find_by_cycle_id!("B2_#{batch_file.clinic.site_code}")
        r3 = Response.find_by_cycle_id!("B3_#{batch_file.clinic.site_code}")

        [r1, r2, r3].each do |r|
          r.survey.should eq(survey)
          r.user.should eq(user)
          r.clinic.should eq(clinic)
          r.submitted_status.should eq(Response::STATUS_SUBMITTED)
          r.batch_file.id.should eq(batch_file.id)
        end

        answer_hash = r1.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
        answer_hash["TextMandatory"].text_answer.should == "B1Val1"
        answer_hash["TextOptional"].should be_nil #not answered
        answer_hash["Date1"].date_answer.should == Date.parse("2011-12-25")
        answer_hash["Time"].time_answer.should == Time.utc(2000, 1, 1, 14, 30)
        answer_hash["Choice"].choice_answer.should == "0"
        answer_hash["Decimal"].decimal_answer.should == 56.77
        answer_hash["Integer"].integer_answer.should == 10
        Answer.all.each { |a| a.has_fatal_warning?.should be false }
        Answer.all.each { |a| a.has_warning?.should be false }
        batch_file.record_count.should == 3
                                   # summary report should exist but not detail report
        batch_file.summary_report_path.should_not be_nil
        File.exist?(batch_file.summary_report_path).should be true
        batch_file.detail_report_path.should be_nil
      end

      it 'file with no errors or warnings - should create the survey responses and answers and should treat textual question choice answers as case insensitive' do
        batch_file = process_batch_file('no_errors_or_warnings_case_insensitive_choices.csv', survey, user)
        expect_successful_status_with_message(batch_file, 'Your file has been processed successfully.')
        Response.count.should == 4
        Answer.count.should eq(44) #4x14 questions = 56, 12 not answered
        batch_file.problem_record_count.should == 0
        batch_file.record_count.should == 4

        r1 = Response.find_by_cycle_id!("B1_#{batch_file.clinic.site_code}")#updated according to ANZARD-234
        r2 = Response.find_by_cycle_id!("B2_#{batch_file.clinic.site_code}")
        r3 = Response.find_by_cycle_id!("B3_#{batch_file.clinic.site_code}")
        r4 = Response.find_by_cycle_id!("B4_#{batch_file.clinic.site_code}")

        [r1, r2, r3, r4].each do |r|
          r.survey.should eq(survey)
          r.user.should eq(user)
          r.clinic.should eq(clinic)
          r.submitted_status.should eq(Response::STATUS_SUBMITTED)
          r.batch_file.id.should eq(batch_file.id)
        end

        # Check that each question options are mapped case-insensitively from batch file answer to choice options
        answer1_hash = r1.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
        answer1_hash['Choice'].choice_answer.should == '0'
        answer1_hash['Choice2'].choice_answer.should == 'y'
        answer1_hash['Choice3'].choice_answer.should == 'yes'

        answer2_hash = r2.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
        answer2_hash['Choice'].choice_answer.should == '1'
        answer2_hash['Choice2'].choice_answer.should == 'y'
        answer2_hash['Choice3'].choice_answer.should == 'yes'

        answer3_hash = r3.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
        answer3_hash['Choice'].choice_answer.should == '99'
        answer3_hash['Choice2'].choice_answer.should == 'y'
        answer3_hash['Choice3'].choice_answer.should == 'yes'

        answer4_hash = r4.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
        answer4_hash['Choice'].choice_answer.should == '99'
        answer4_hash['Choice2'].choice_answer.should == 'y'
        answer4_hash['Choice3'].choice_answer.should == 'unknown'


        Answer.all.each { |a| a.has_fatal_warning?.should be false }
        Answer.all.each { |a| a.has_warning?.should be false }
        batch_file.record_count.should == 4
        # summary report should exist but not detail report
        batch_file.summary_report_path.should_not be_nil
        File.exist?(batch_file.summary_report_path).should be true
        batch_file.detail_report_path.should be_nil
      end
    end

    describe "with validation errors" do
      it "file that just has blank rows fails on cycle id since cycle ids are missing" do
        batch_file = process_batch_file('blank_rows.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded is missing one or more cycle IDs. Each record must have a cycle ID. Processing stopped on CSV row 1")
        Response.count.should == 0
        Answer.count.should == 0
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it "file with missing cycle ids should be rejected completely and no reports generated" do
        batch_file = process_batch_file('missing_cycle_id.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded is missing one or more cycle IDs. Each record must have a cycle ID. Processing stopped on CSV row 2")
        Response.count.should == 0
        Answer.count.should == 0
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      # ToDo: Determine whether this is affected - can't have duplicate id in same year but may be possible if site is appended
      it "file with duplicate cycle ids within the file should be rejected completely and no reports generated" do
        batch_file = process_batch_file('duplicate_cycle_id.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded contained duplicate cycle IDs. Each cycle ID can only be used once. Processing stopped on CSV row 3")
        Response.count.should == 0
        Answer.count.should == 0
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it "file with duplicate cycle ids within the file (with whitespace padding) should be rejected completely and no reports generated" do
        batch_file = process_batch_file('duplicate_cycle_id_whitespace.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded contained duplicate cycle IDs. Each cycle ID can only be used once. Processing stopped on CSV row 3")
        Response.count.should == 0
        Answer.count.should == 0
        expect_no_records_and_no_problem_records(batch_file)
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it "should reject records with missing mandatory fields" do
        batch_file = process_batch_file('missing_mandatory_fields.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        expect_summary_report_and_detail_report(batch_file)
      end

      it 'should reject records with missing mandatory fields - where the column is missing entirely - and no reports generated' do
        batch_file = process_batch_file('missing_mandatory_column.csv', survey, user)
        expect_fail_status_with_message(batch_file, 'The file you uploaded is missing the following column(s): TextMandatory')
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.problem_record_count.should be_nil
        expect_no_summary_report_and_no_detail_report(batch_file)
      end

      it "should reject records with choice answers that are not one of the allowed values for the question" do
        batch_file = process_batch_file('incorrect_choice_answer_value.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        expect_summary_report_and_detail_report(batch_file)
      end

      it "should reject records with integer answers that are badly formed" do
        batch_file = process_batch_file('bad_integer.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        expect_summary_report_and_detail_report(batch_file)
      end

      it "should reject records with decimal answers that are badly formed" do
        batch_file = process_batch_file('bad_decimal.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        expect_summary_report_and_detail_report(batch_file)
      end

      it "should reject records with time answers that are badly formed" do
        batch_file = process_batch_file('bad_time.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        expect_summary_report_and_detail_report(batch_file)
      end

      it "should reject records with date answers that are badly formed" do
        batch_file = process_batch_file('bad_date.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        expect_summary_report_and_detail_report(batch_file)
      end

      it "should accept records where the cycle id is already in the system in the same survey and a different year" do
        create(:response, survey: survey, cycle_id: "B2", year_of_registration: "2005")
        batch_file = process_batch_file('no_errors_or_warnings.csv', survey, user, 2010)
        expect_successful_status_with_message(batch_file, 'Your file has been processed successfully.')
        response = Response.find_by!(cycle_id: "B2_#{batch_file.clinic.site_code}", year_of_registration: 2010)#updated according to ANZARD-234
        response.survey.should eq(survey)
        response.user.should eq(user)
        response.clinic.should eq(clinic)
        response.submitted_status.should eq(Response::STATUS_SUBMITTED)
        response.batch_file.id.should eq(batch_file.id)
        answer_hash = response.answers.reduce({}) { |hash, answer| hash[answer.question.code] = answer; hash }
        answer_hash['TextMandatory'].text_answer.should == 'B2Val1'
        answer_hash['Date1'].date_answer.should == Date.parse('2012-01-01')
        answer_hash['Time'].time_answer.should == Time.utc(2000, 1, 1, 23, 59)
        answer_hash['Choice'].choice_answer.should == '1'
        answer_hash['Decimal'].decimal_answer.should == 44
        answer_hash['Integer'].integer_answer.should == 9
      end

      it "should reject records where the cycle id is already in the system within the survey and year of treatment" do
        create(:response, survey: survey, cycle_id: "B2_#{clinic.site_code}", year_of_registration: "2005")#updated according to ANZARD-234
        batch_file = process_batch_file('no_errors_or_warnings.csv', survey, user, 2005)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 1 #the one we created earlier
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)
        File.exist?(batch_file.summary_report_path).should be true

        csv_file = batch_file.detail_report_path
        rows = CSV.read(csv_file)
        rows.size.should eq(2)
        rows[0].should eq(["CYCLE_ID", "Column Name", "Type", "Value", "Message"])
        rows[1].should eq(['B2', 'CYCLE_ID', 'Error', 'B2', 'Cycle ID B2 has already been used within the year of treatment.'])
      end

      it "should reject records where the cycle id is already in the system within the survey and year of treatment even with whitespace padding" do
        create(:response, survey: survey, cycle_id: "B2_#{clinic.site_code}", year_of_registration: "2005")#updated according to ANZARD-234
        batch_file = process_batch_file('no_errors_or_warnings_whitespace.csv', survey, user, 2005)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 1 #the one we created earlier
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)
        File.exist?(batch_file.summary_report_path).should be true

        csv_file = batch_file.detail_report_path
        rows = CSV.read(csv_file)
        rows.size.should eq(2)
        rows[0].should eq(["CYCLE_ID", "Column Name", "Type", "Value", "Message"])
        rows[1].should eq(['B2', 'CYCLE_ID', 'Error', 'B2', 'Cycle ID B2 has already been used within the year of treatment.'])
      end

      it "can detect both duplicate cycle id and other errors on the same record" do
        create(:response, survey: survey, cycle_id: "B2_#{clinic.site_code}", year_of_registration: "2005")#updated according to ANZARD-234
        batch_file = process_batch_file('missing_mandatory_fields.csv', survey, user, 2005)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 1 #the one we created earlier
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)
        File.exist?(batch_file.summary_report_path).should be true

        csv_file = batch_file.detail_report_path
        rows = CSV.read(csv_file)
        rows.size.should eq(3)
        rows[0].should eq(["CYCLE_ID", "Column Name", "Type", "Value", "Message"])
        rows[1].should eq(['B2', 'CYCLE_ID', 'Error', 'B2', 'Cycle ID B2 has already been used within the year of treatment.'])
        rows[2].should eq(['B2', 'TextMandatory', 'Error', '', 'This question is mandatory'])
      end
    end

    describe "with warnings" do
      it "warns on number range issues" do
        batch_file = process_batch_file('number_out_of_range.csv', survey, user)
        expect_review_status_with_message(batch_file, "The file you uploaded has one or more warnings. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)
      end

      it "accepts number range issues if forced to" do
        # sad path covered earlier
        batch_file = BatchFile.create!(file: Rack::Test::UploadedFile.new('test_data/survey/batch_files/number_out_of_range.csv', 'text/csv'), survey: survey, user: user, clinic: clinic, year_of_registration: 2009)
        batch_file.process
        batch_file.reload

        expect_review_status_with_message(batch_file, "The file you uploaded has one or more warnings. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)

        batch_file.status = BatchFile::STATUS_IN_PROGRESS # the controller sets it to in progress before forcing processing
        batch_file.process(:force)
        batch_file.reload

        expect_successful_status_with_message(batch_file, "Your file has been processed successfully.")
        Response.count.should == 3
        Answer.count.should == 29
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)

      end

      it "should warn on records which fail cross-question validations" do
        batch_file = process_batch_file('cross_question_error.csv', survey, user)
        expect_review_status_with_message(batch_file, "The file you uploaded has one or more warnings. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)

        csv_file = batch_file.detail_report_path
        rows = CSV.read(csv_file)
        rows.size.should eq(2)
        rows[0].should eq(['CYCLE_ID', 'Column Name', 'Type', 'Value', 'Message'])
        rows[1].should eq(['B3', 'Date1', 'Warning', '2010-05-29', 'D1 must be >= D2'])
      end

      it "should accepts cross-question validation failures if forced to" do
        batch_file = process_batch_file('cross_question_error.csv', survey, user)
        expect_review_status_with_message(batch_file, "The file you uploaded has one or more warnings. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)

        batch_file.status = BatchFile::STATUS_IN_PROGRESS # the controller sets it to in progress before forcing processing
        batch_file.process(:force)
        batch_file.reload

        expect_successful_status_with_message(batch_file, "Your file has been processed successfully.")
        Response.count.should == 3
        Answer.count.should == 30
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)
      end

      it "should warn on records which fail cross-question validations - date time quad failure" do
        batch_file = process_batch_file('cross_question_error_datetime_comparison.csv', survey, user)
        expect_review_status_with_message(batch_file, "The file you uploaded has one or more warnings. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 1
        expect_summary_report_and_detail_report(batch_file)
        File.exist?(batch_file.summary_report_path).should be true

        csv_file = batch_file.detail_report_path
        rows = CSV.read(csv_file)
        rows.size.should eq(2)
        rows[0].should eq(['CYCLE_ID', 'Column Name', 'Type', 'Value', 'Message'])
        rows[1].should eq(['B3', 'Date1', 'Warning', '2010-05-29', 'D1+T1 must be > D2+T2'])
      end


    end

    describe "with a range of errors and warnings" do
      it "should produce a CSV detail report file with correct error and warning details" do
        batch_file = process_batch_file('a_range_of_problems.csv', survey, user)
        expect_fail_status_with_message(batch_file, "The file you uploaded did not pass validation. Please review the reports for details.")
        Response.count.should == 0
        Answer.count.should == 0
        batch_file.record_count.should == 3
        batch_file.problem_record_count.should == 3

        csv_file = batch_file.detail_report_path
        rows = CSV.read(csv_file)
        rows.size.should eq(7)
        rows[0].should eq(["CYCLE_ID", "Column Name", "Type", "Value", "Message"])
        rows[1].should eq(['B1', 'Date1', 'Error', '2011-ab-25', 'Answer is invalid (must be a valid date)'])
        rows[2].should eq(['B1', 'Decimal', 'Error', 'a.77', 'Answer is the wrong format (expected a decimal number)'])
        rows[3].should eq(['B1', 'TextMandatory', 'Error', '', 'This question is mandatory'])
        rows[4].should eq(['B2', 'Integer', 'Warning', '3', 'Answer should be at least 5'])
        rows[5].should eq(['B2', 'Time', 'Error', 'ab:59', 'Answer is invalid (must be a valid time)'])
        rows[6].should eq(['B3', 'Date1', 'Warning', '2010-05-29', 'D1 must be >= D2'])

        File.exist?(batch_file.summary_report_path).should be true
      end
    end
  end

  describe "Destroy" do
    it "should remove the associated data file and any reports" do
      clinic_allocation
      batch_file = process_batch_file('a_range_of_problems.csv', survey, user)
      path = batch_file.file.path
      summary_path = batch_file.summary_report_path
      detail_path = batch_file.detail_report_path

      path.should_not be_nil
      summary_path.should_not be_nil
      detail_path.should_not be_nil

      File.exist?(path).should be true
      File.exist?(summary_path).should be true
      File.exist?(detail_path).should be true

      batch_file.destroy
      File.exist?(path).should be false
      File.exist?(summary_path).should be false
      File.exist?(detail_path).should be false
    end
  end

  def process_batch_file(file_name, survey, user, year_of_registration=2009)
    batch_file = BatchFile.create!(file: Rack::Test::UploadedFile.new('test_data/survey/batch_files/' + file_name, 'text/csv'), survey: survey, user: user, clinic: clinic, year_of_registration: year_of_registration)
    batch_file.process
    batch_file.reload
    batch_file
  end

  def expect_successful_status_with_message(batch_file, message)
    expect_status_and_message(batch_file, 'Processed Successfully', message)
  end

  def expect_review_status_with_message(batch_file, message)
    expect_status_and_message(batch_file, 'Needs Review', message)
  end

  def expect_fail_status_with_message(batch_file, message)
    expect_status_and_message(batch_file, 'Failed', message)
  end

  def expect_status_and_message(batch_file, status, message)
    expect(batch_file.status).to eq(status)
    expect(batch_file.message).to eq(message)
  end

  def expect_summary_report_and_detail_report(batch_file)
    expect(batch_file.summary_report_path).to_not be_nil
    expect(batch_file.detail_report_path).to_not be_nil
  end

  def expect_no_summary_report_and_no_detail_report(batch_file)
    expect(batch_file.summary_report_path).to be_nil
    expect(batch_file.detail_report_path).to be_nil
  end

  def expect_no_records_and_no_problem_records(batch_file)
    expect(batch_file.record_count).to be_nil
    expect(batch_file.problem_record_count).to be_nil
  end


end

