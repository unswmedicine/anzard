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

describe Response do
  describe "Associations" do
    it { should belong_to :user }
    it { should belong_to :clinic }
    it { should have_many :answers }
    it { should belong_to :batch_file }
  end

  describe "Validations" do
    it { should validate_presence_of :cycle_id }
    it { should validate_length_of(:cycle_id).is_at_least(1).is_at_most(20)}
    it { should validate_presence_of :user }
    it { should validate_presence_of :survey_id }
    it { should validate_presence_of :year_of_registration }

    it "should validate that submitted_status is one of the allowed types" do
      [Response::STATUS_SUBMITTED, Response::STATUS_UNSUBMITTED].each do |value|
        should allow_value(value).for(:submitted_status)
      end
      build(:response, submitted_status: nil).should_not be_valid
      build(:response, submitted_status: "Blah").should_not be_valid
    end

    it "should validate that cycle id is unique within survey" do
      first = create(:response, cycle_id: "abcd")
      second = build(:response, survey: first.survey, cycle_id: first.cycle_id)
      second.should_not be_valid
      second.errors.full_messages.should eq(["Cycle ID abcd has already been used."])
      diff_survey = build(:response, survey: create(:survey), cycle_id: first.cycle_id)
      diff_survey.should be_valid
    end

    it "should strip leading/trailing spaces from cycle ids before validating" do
      first = create(:response, cycle_id: " abcd ")
      first.cycle_id.should eq("abcd")

      second = build(:response, survey: first.survey, cycle_id: " abcd")
      second.should_not be_valid
      second.errors.full_messages.should eq(["Cycle ID abcd has already been used."])
    end
  end

  describe "Scopes" do
    it "for survey scope should return responses for the given survey" do
      survey_a = create(:survey)
      survey_b = create(:survey)
      r1 = create(:response, survey: survey_a)
      r2 = create(:response, survey: survey_b)
      r3 = create(:response, survey: survey_a)
      matches = Response.for_survey(survey_a).collect(&:id).sort
      matches.should eq([r1.id, r3.id])
    end

    it "unsubmitted scope should return responses that are unsubmitted" do
      r1 = create(:response, submitted_status: Response::STATUS_UNSUBMITTED)
      r2 = create(:response, submitted_status: Response::STATUS_SUBMITTED)
      r3 = create(:response, submitted_status: Response::STATUS_UNSUBMITTED)
      matches = Response.unsubmitted.collect(&:id).sort
      matches.should eq([r1.id, r3.id])
    end
  end

  describe "Getting submitted responses by survey, clinic and year of reg" do
    before(:each) do
      @survey_a = create(:survey)
      @survey_b = create(:survey)
      @clinic_a = create(:clinic, unit_code: 100, unit_name: 'Unit 100', site_code: 100)
      @clinic_b = create(:clinic, unit_code: 200, unit_name: 'Unit 200', site_code: 200)
      @clinic_c = create(:clinic, unit_code: 100, unit_name: 'Unit 100', site_code: 101)
      @r1 = create(:response, survey: @survey_a, clinic: @clinic_a, year_of_registration: 2001, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "1").id
      @r2 = create(:response, survey: @survey_a, clinic: @clinic_a, year_of_registration: 2001, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "2").id
      @r3 = create(:response, survey: @survey_a, clinic: @clinic_a, year_of_registration: 2002, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "3").id
      @r4 = create(:response, survey: @survey_a, clinic: @clinic_b, year_of_registration: 2001, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "4").id
      @r5 = create(:response, survey: @survey_a, clinic: @clinic_b, year_of_registration: 2002, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "5").id
      @r6 = create(:response, survey: @survey_a, clinic: @clinic_b, year_of_registration: 2003, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "6").id
      @r7 = create(:response, survey: @survey_b, clinic: @clinic_a, year_of_registration: 2001, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "7").id
      @r8 = create(:response, survey: @survey_a, clinic: @clinic_c, year_of_registration: 2001, submitted_status: Response::STATUS_SUBMITTED, cycle_id: "8").id
      @r9 = create(:response, survey: @survey_a, clinic: @clinic_a, year_of_registration: 2001, submitted_status: Response::STATUS_UNSUBMITTED).id
    end

    it "should return all submitted responses for survey when clinic and year of reg not provided" do
      Response.for_survey_clinic_and_year_of_registration(@survey_a, "", "", "").collect(&:id).should eq([@r1, @r2, @r3, @r4, @r5, @r6, @r8])
    end

    it "should filter by unit when provided" do
      Response.for_survey_clinic_and_year_of_registration(@survey_a, @clinic_a.unit_code, "", "").collect(&:id).should eq([@r1, @r2, @r3, @r8])
    end

    it "should filter by unit and site when provided" do
      Response.for_survey_clinic_and_year_of_registration(@survey_a, @clinic_a.unit_code, @clinic_a.site_code, "").collect(&:id).should eq([@r1, @r2, @r3])
    end

    it "should filter by year of reg when provided" do
      Response.for_survey_clinic_and_year_of_registration(@survey_a, "", "", "2001").collect(&:id).should eq([@r1, @r2, @r4, @r8])
    end

    it "should filter by clinic unit and year of reg when both provided" do
      Response.for_survey_clinic_and_year_of_registration(@survey_a, @clinic_a.unit_code, "", "2001").collect(&:id).should eq([@r1, @r2, @r8])
    end

    it "should filter by clinic unit and site and year of reg when all provided" do
      Response.for_survey_clinic_and_year_of_registration(@survey_a, @clinic_a.unit_code, @clinic_a.site_code, "2001").collect(&:id).should eq([@r1, @r2])
    end
  end

  describe "Getting the full set of possible years of registration" do
    it "returns unique values in ascending order" do
      create(:response, year_of_registration: 2009)
      create(:response, year_of_registration: 2007)
      create(:response, year_of_registration: 2009)
      create(:response, year_of_registration: 2011)
      Response.existing_years_of_registration.should eq([2007, 2009, 2011])
    end
  end

  describe "submit" do
    let(:response) { create(:response) }
    it "should set the status of the response when complete" do
      response.stub(:validation_status) { Response::COMPLETE }
      response.submitted_status.should eq Response::STATUS_UNSUBMITTED

      response.submit!

      response.submitted_status.should eq Response::STATUS_SUBMITTED
      response.reload

      response.submitted_status.should eq Response::STATUS_SUBMITTED
    end
    it "should set the status of the response when complete with warnings" do
      response.stub(:validation_status) { Response::COMPLETE_WITH_WARNINGS }
      response.submitted_status.should eq Response::STATUS_UNSUBMITTED

      response.submit!

      response.submitted_status.should eq Response::STATUS_SUBMITTED
      response.reload

      response.submitted_status.should eq Response::STATUS_SUBMITTED
    end
    it "can't submit a response incomplete" do
      response.stub(:validation_status) { Response::INCOMPLETE }

      expect { response.submit! }.to raise_error("Can't submit with status Incomplete")
    end
  end

  describe "submit_warning" do
    let(:response) { create(:response) }
    it "dies on complete" do
      response.stub(:validation_status) { Response::COMPLETE }
      response.submit_warning.should be_nil
    end
    it "shows a warning for incomplete" do
      response.stub(:validation_status) { Response::INCOMPLETE }
      response.submit_warning.should eq "This data entry form is incomplete and can't be submitted."
    end
    it "shows a warning for complete with warnings" do
      response.stub(:validation_status) { Response::COMPLETE_WITH_WARNINGS }
      response.submit_warning.should eq "This data entry form has warnings. Double check them. If you believe them to be correct, contact a supervisor."
    end
  end

  describe "status" do
    before(:each) do
      @survey = create(:survey)
      @section1 = create(:section, survey: @survey)
      @section2 = create(:section, survey: @survey)

      @q1 = create(:question, section: @section1, mandatory: true, question_type: "Integer", number_min: 10)
      @q2 = create(:question, section: @section1, mandatory: true)
      @q3 = create(:question, section: @section1, mandatory: false)

      @q4 = create(:question, section: @section2, mandatory: true)
      @q5 = create(:question, section: @section2, mandatory: true)
      @q6 = create(:question, section: @section2, mandatory: false)
      @q7 = create(:question, section: @section2, mandatory: false, question_type: "Integer", number_max: 15)

      @response = create(:response, survey: @survey)
    end
    describe "of a response" do
      it "incomplete when nothing done yet" do
        @response.validation_status.should eq "Incomplete"
      end
      it "incomplete section 1" do
        create(:answer, response: @response, question: @q1, integer_answer: 3)
        @response.save!
        @response.reload

        @response.validation_status.should eq "Incomplete"
      end
      it "incomplete section 2" do
        create(:answer, response: @response, question: @q7, integer_answer: 16)
        @response.save!
        @response.reload

        @response.validation_status.should eq "Incomplete"
      end
      it "Complete with warnings" do
        create(:answer, question: @q1, response: @response, integer_answer: 9)
        create(:answer, question: @q2, response: @response)
        create(:answer, question: @q4, response: @response)
        create(:answer, question: @q5, response: @response)
        @response.reload
        @response.save!
        @response.validation_status.should eq "Complete with warnings"
      end
      it "Complete with no warnings" do
        create(:answer, question: @q1, response: @response, integer_answer: 11)
        create(:answer, question: @q2, response: @response)
        create(:answer, question: @q4, response: @response)
        create(:answer, question: @q5, response: @response)
        @response.reload
        @response.save!

        @response.validation_status.should eq "Complete"
      end
      it "should recognise section 2 as incomplete and mark the response as incomplete even if section 1 is complete" do
        create(:answer, question: @q1, response: @response, integer_answer: 11)
        create(:answer, question: @q2, response: @response)
        @response.reload
        @response.save!

        @response.validation_status.should eq "Incomplete"
      end
    end
    describe "of a section" do

      it "should be incomplete if no answers have been saved yet" do
        @response.section_started?(@section1).should be false
        @response.status_of_section(@section1).should eq("Incomplete")
        @response.section_started?(@section2).should be false
        @response.status_of_section(@section2).should eq("Incomplete")
      end

      it "should be incomplete if at least one question is answered but not all mandatory questions are answered" do
        create(:answer, question: @q1, response: @response)
        @response.reload

        @response.section_started?(@section1).should be true
        @response.status_of_section(@section1).should eq("Incomplete")
        @response.section_started?(@section2).should be false
        @response.status_of_section(@section2).should eq("Incomplete")
      end

      it "should be complete once all mandatory questions are answered" do
        create(:answer, question: @q1, response: @response)
        create(:answer, question: @q2, response: @response)
        @response.reload

        @response.section_started?(@section1).should be true
        @response.status_of_section(@section1).should eq("Complete")
      end

      it "should be complete with warnings when all mandatory questions are answered but a warning is present" do
        create(:answer, question: @q4, response: @response)
        create(:answer, question: @q5, response: @response)
        create(:answer, question: @q7, response: @response, answer_value: 16)
        @response.reload

        @response.section_started?(@section2).should be true
        @response.status_of_section(@section2).should eq 'Complete with warnings'

      end

      it "should be incomplete if there's any range warnings present and not all mandatory questions are answered" do
        create(:answer, question: @q1, response: @response, answer_value: "5")
        @response.reload

        @response.section_started?(@section1).should be true
        @response.status_of_section(@section1).should eq("Incomplete")
      end

      it "should be incomplete if all mandatory questions are answered and garbage is stored" do
        create(:answer, question: @q4, response: @response)
        create(:answer, question: @q5, response: @response)
        create(:answer, question: @q7, answer_value: 'abvcasdfsadf', response: @response)
        @response.reload

        @response.section_started?(@section2).should be true
        @response.status_of_section(@section2).should eq 'Incomplete'
      end

      it "should be incomplete if all mandatory questions are answered and a cross-question validation fails" do
        create(:answer, question: @q7, answer_value: 'abvcasdfsadf', response: @response)
        @response.reload

        @response.section_started?(@section2).should be true
        @response.status_of_section(@section2).should eq 'Incomplete'
      end

      it "shows complete with warnings if a CQV fails and a range check fails" do
        @section3 = create(:section, survey: @survey)
        @q8 = create(:question, section: @section3, mandatory: false, question_type: "Date")
        @q9 = create(:question, section: @section3, mandatory: false, question_type: "Integer", number_min: 0)

        create(:cross_question_validation, rule: 'comparison', operator: '<', question: @q8, related_question: @q8)
        create(:answer, question: @q8, answer_value: Date.today, response: @response)
        create(:answer, question: @q9, answer_value: -1, response: @response)
        @response.reload

        @response.section_started?(@section3).should be true
        @response.status_of_section(@section3).should eq 'Complete with warnings'
      end

      it "takes unanswered questions into account" do
        survey = create(:survey)
        response = create(:response, survey: survey)
        section = create(:section, survey: survey)

        question = create(:question, section: section, mandatory: false, question_type: Question::TYPE_TEXT)
        trigger = create(:question, section: section, mandatory: false, question_type: Question::TYPE_INTEGER)

        create(:cross_question_validation,
                rule: 'present_if_const',
                conditional_operator: '==',
                conditional_constant: '1',
                question: question,
                related_question: trigger)

        create(:answer, question: trigger, answer_value: '1', response: response)
        # no answer for particular question
        response.reload

        response.section_started?(section).should be true
        response.status_of_section(section).should eq 'Complete with warnings'
      end
    end
  end

  describe "Finding out if a response has warnings or fatal warnings" do
    before(:each) do
      @survey = create(:survey)
      @section = create(:section, survey: @survey)
      @question1 = create(:question, mandatory: true, section: @section, code: "A", question_type: Question::TYPE_INTEGER, number_min: 5)
      @question2 = create(:question, mandatory: false, section: @section, code: "B")
    end

    it "both warnings and fatal warnings are true if mandatory questions are missing" do
      response = create(:response, survey: @survey)
      response.fatal_warnings?.should be true
      response.warnings?.should be true
      response.build_answers_from_hash({"B" => "B answer"})
      response.save!
      response.reload
      response.fatal_warnings?.should be true
      response.warnings?.should be true
    end

    it "both warnings and fatal warnings are false if mandatory questions are all answered" do
      response = create(:response, survey: @survey)
      response.build_answers_from_hash({"A" => "10"})
      response.save!
      response.reload
      response.fatal_warnings?.should be false
      response.warnings?.should be false
    end

    it "has fatal warnings and has warnings are both true if at least one answer has a fatal warning" do
      response = create(:response, survey: @survey)
      response.build_answers_from_hash({"A" => "A answer", "B" => "B answer"}) #A answer is invalid
      response.fatal_warnings?.should be true
      response.warnings?.should be true
    end

    it "has fatal warnings is false but has warnings is true if at least one answer has a warning but none have fatal warnings" do
      response = create(:response, survey: @survey)
      response.build_answers_from_hash({"A" => "2", "B" => "B answer"}) #A is out of range
      response.fatal_warnings?.should be false
      response.warnings?.should be true
    end

    it "has fatal warnings and has warnings are both false if no answers have warnings or fatal warnings" do
      response = create(:response, survey: @survey)
      response.build_answers_from_hash({"A" => "7", "B" => "B answer"}) #A is out of range
      response.fatal_warnings?.should be false
      response.warnings?.should be false
    end
  end
end
