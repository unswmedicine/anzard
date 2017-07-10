require 'rails_helper'

describe StatsReport do

  let(:survey_a) { create(:survey) }
  let(:survey_b) { create(:survey) }
  let(:clinic_a) { create(:clinic) }
  let(:clinic_b) { create(:clinic) }

  describe "Empty" do
    it "should return true if the survey has no responses" do
      create(:response, survey: survey_b, year_of_registration: 2001)
      StatsReport.new(survey_a).should be_empty
    end
    it "should return true if the survey has no responses" do
      create(:response, survey: survey_a, year_of_registration: 2001)
      StatsReport.new(survey_a).should_not be_empty
    end
  end

  describe "Getting the possible values for year of registration for a survey" do
    it "should return an array of the years that responses exist for" do
      create(:response, survey: survey_a, year_of_registration: 2001)
      create(:response, survey: survey_a, year_of_registration: 2005)
      create(:response, survey: survey_a, year_of_registration: 2007)
      create(:response, survey: survey_b, year_of_registration: 2002)
      create(:response, survey: survey_b, year_of_registration: 2001)

      StatsReport.new(survey_a).years.should eq([2001, 2005, 2007])
      StatsReport.new(survey_b).years.should eq([2001, 2002])
    end
  end

  describe "Getting the count of responses for a year/status/clinic combination" do
    it "should return the correct count" do
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_a, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_a, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_a, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_b, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_b, submitted_status: Response::STATUS_SUBMITTED)

      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_a, submitted_status: Response::STATUS_UNSUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_b, submitted_status: Response::STATUS_UNSUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_b, submitted_status: Response::STATUS_UNSUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2001, clinic: clinic_b, submitted_status: Response::STATUS_UNSUBMITTED)

      create(:response, survey: survey_a, year_of_registration: 2005, clinic: clinic_a, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2005, clinic: clinic_b, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2005, clinic: clinic_b, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2005, clinic: clinic_b, submitted_status: Response::STATUS_SUBMITTED)

      create(:response, survey: survey_a, year_of_registration: 2007, clinic: clinic_a, submitted_status: Response::STATUS_UNSUBMITTED)
      create(:response, survey: survey_a, year_of_registration: 2007, clinic: clinic_a, submitted_status: Response::STATUS_UNSUBMITTED)

      create(:response, survey: survey_b, year_of_registration: 2002, clinic: clinic_a, submitted_status: Response::STATUS_SUBMITTED)
      create(:response, survey: survey_b, year_of_registration: 2001, clinic: clinic_a, submitted_status: Response::STATUS_SUBMITTED)

      report = StatsReport.new(survey_a)
      report.response_count(2001, Response::STATUS_SUBMITTED, clinic_a.id).should eq(3)
      report.response_count(2001, Response::STATUS_SUBMITTED, clinic_b.id).should eq(2)
      report.response_count(2001, Response::STATUS_UNSUBMITTED, clinic_a.id).should eq(1)
      report.response_count(2001, Response::STATUS_UNSUBMITTED, clinic_b.id).should eq(3)

      report.response_count(2005, Response::STATUS_SUBMITTED, clinic_a.id).should eq(1)
      report.response_count(2005, Response::STATUS_SUBMITTED, clinic_b.id).should eq(3)
      report.response_count(2005, Response::STATUS_UNSUBMITTED, clinic_a.id).should eq('none')
      report.response_count(2005, Response::STATUS_UNSUBMITTED, clinic_b.id).should eq('none')

      report.response_count(2007, Response::STATUS_SUBMITTED, clinic_a.id).should eq('none')
      report.response_count(2007, Response::STATUS_SUBMITTED, clinic_b.id).should eq('none')
      report.response_count(2007, Response::STATUS_UNSUBMITTED, clinic_a.id).should eq(2)
      report.response_count(2007, Response::STATUS_UNSUBMITTED, clinic_b.id).should eq('none')
    end
  end

end