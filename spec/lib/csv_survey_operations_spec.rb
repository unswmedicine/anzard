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

def fqn(filename)
  # fully-qualified name.
  Rails.root.join('test_data', 'survey', filename)
end

def counts_should_eq_0(*models)
  counts = models.map { |m| m.count }
  expect(counts).to eq ([0] * models.length)
end

describe CsvSurveyOperations do
  describe "create_survey" do

    let(:good_question_file) { fqn('survey_questions.csv') }
    let(:bad_question_file) { fqn('bad_questions.csv') }
    let(:duplicate_name_question_file) { fqn('duplicate_name_questions.csv') }
    let(:good_options_file) { fqn('survey_options.csv') }
    let(:bad_options_file) { fqn('bad_options.csv') }
    let(:good_cqv_file) { fqn('cross_question_validations.csv') }
    let(:bad_cqv_file) { fqn('bad_cross_question_validations.csv') }

    it "works on good input" do
      s = create_survey('some_name', good_question_file, good_options_file, good_cqv_file)
      expect(s.sections.count).to eq 3
      expect(s.sections.first.questions.count).to eq 6
      expect(s.sections.second.questions.count).to eq 5
      expect(s.sections.third.questions.count).to eq 3

      expect(Section.find_by_name!('0').section_order).to eq 0
      expect(Section.find_by_name!('1').section_order).to eq 1
    end

    it "should be transactional with a bad cqv file" do
      expect(lambda {
        create_survey('some name', good_question_file, good_options_file, bad_cqv_file)
      }).to raise_error(ActiveRecord::RecordNotFound)
      counts_should_eq_0 Survey, Question, CrossQuestionValidation, Answer, Response, QuestionOption

    end

    it "should be transactional with a bad options file" do
      expect(lambda {
        create_survey('some name', good_question_file, bad_options_file, good_cqv_file)
      }).to raise_error(ActiveRecord::RecordInvalid)
      counts_should_eq_0 Survey, Question, CrossQuestionValidation, Answer, Response, QuestionOption

    end
    it "should be transactional with a bad question file" do
      expect(lambda {
        create_survey('some name', bad_question_file, good_options_file, good_cqv_file)
      }).to raise_error(ActiveRecord::RecordInvalid)
      counts_should_eq_0 Survey, Question, CrossQuestionValidation, Answer, Response, QuestionOption
    end

    it 'should reject if there are multiple questions with the same code' do
      expect(lambda {
        create_survey('some name', duplicate_name_question_file, good_options_file, good_cqv_file)
      }).to raise_error(InputError)

      counts_should_eq_0 Survey, Question, CrossQuestionValidation, Answer, Response, QuestionOption
    end

  end

  describe "make_cqv" do
    def run_make_cqv_test(survey, hash)
      begin
        make_cqv(survey, hash)
        continued = true
      rescue
        continued = false
      end

      continued
    end

    before :each do
      @survey = create :survey
      @section = create :section, survey: @survey
      @error_message = 'q2 was date, q1 was not expected constant (-1)'
      @q1 = create :question, section: @section, question_type: 'Integer', code: "q1"
      @q2 = create :question, section: @section, question_type: 'Integer', code: "q2"
      @q3 = create :question, section: @section, question_type: 'Integer', code: "q3"

      @multi_related_hash = {"related_question_list" => "q2, q3",
                             "rule" => "multi_hours_date_to_date",
                             "operator" => "<=",
                             "constant" => "0",
                             "error_message" => @error_message,
                             "question_code" => "q1"}

      @multi_rule_secondary_hash = {"rule_label" => "secondary",
                                    "rule" => "comparison",
                                    "operator" => "==",
                                    "error_message" => @error_message,
                                    "question_code" => "q1",
                                    "related_question_code" => "q2"}

    end
    it 'should accept if it can map question lists to questions' do
      expect(run_make_cqv_test(@survey, @multi_related_hash)).to be true
    end

    it 'should reject if it can\'t map question lists to questions' do
      new_hash = @multi_related_hash
      new_hash['related_question_list'] = "q2, q3, q4"
      expect(run_make_cqv_test(@survey, new_hash)).to be false
    end


  end

  describe "make_cqvs" do
    def run_make_cqvs_test(survey, hashes)
      count = CrossQuestionValidation.count
      begin
        make_cqvs(survey, hashes)
      rescue
        count +=0 #stops rubymine whinging
      end
      CrossQuestionValidation.count - count
    end

    before :each do
      @survey = create :survey
      @section = create :section, survey: @survey
      @error_message = 'q2 was date, q1 was not expected constant (-1)'
      @q1 = create :question, section: @section, question_type: 'Integer', code: "q1"
      @q2 = create :question, section: @section, question_type: 'Integer', code: "q2"
      @q3 = create :question, section: @section, question_type: 'Integer', code: "q3"

      @hashes = []


      @hashes << {
          "related_question_list" => "q2, q3",
          "rule" => "multi_hours_date_to_date",
          "operator" => "<=",
          "constant" => "0",
          "error_message" => @error_message,
          "question_code" => "q1"
      }

      @hashes << {
          "rule" => "comparison",
          "operator" => "==",
          "error_message" => @error_message,
          "question_code" => "q1",
          "related_question_code" => "q2"
      }

      @hashes << {
          "related_question_list" => "q2, q3",
          "rule" => "multi_hours_date_to_date",
          "operator" => "<=",
          "constant" => "0",
          "error_message" => @error_message,
          "question_code" => "q1"
      }


    end

    it "should create CQVs for all rules passed in, assuming they're all valid" do
      expect(run_make_cqvs_test(@survey, @hashes)).to eq 3
    end

    it 'should stop creating CQVs if one fails' do
      new_hashes = @hashes.dup
      new_hashes[1]['related_question_list'] = "q2, q3, q4"
      expect(run_make_cqvs_test(@survey, new_hashes)).to eq 1
    end


  end

end
