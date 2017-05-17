require 'rails_helper'

describe CsvGenerator do
  let(:survey) { create(:survey, name: "Survey One") }
  let(:hospital) { create(:hospital, name: "Royal North Shore", unit: "IVF", site: "RNS") }

  describe "Generating the filename" do

    it "includes only survey name when no hospital or year of registration" do
      expect(CsvGenerator.new(survey.id, "", "", "").csv_filename).to eq("survey_one.csv")
    end

    it "includes survey name and hospital when hospital set" do
      expect(CsvGenerator.new(survey.id, hospital.id, "", "").csv_filename).to eq("survey_one_rns.csv")

    end

    it "includes survey name and year of registration when year of registration set" do
      expect(CsvGenerator.new(survey.id, "", "2009", "").csv_filename).to eq("survey_one_2009.csv")

    end

    it "includes survey name, hospital and year of registration when all are set" do
      expect(CsvGenerator.new(survey.id, hospital.id, "2009", "").csv_filename).to eq("survey_one_rns_2009.csv")

    end

    it "makes the survey name safe for use in a filename" do
      survey = create(:survey, name: "SurVey %/\#.()A,|")
      expect(CsvGenerator.new(survey.id, "", "", "").csv_filename).to eq("survey_a.csv")
    end
  end

  describe "Checking for emptiness" do
    it "returns true if there's no matching records" do
      expect(Response).to receive(:for_survey_hospital_and_year_of_registration).with(survey, hospital.id, "2009", "").and_return([])
      expect(CsvGenerator.new(survey.id, hospital.id, "2009", "")).to be_empty
    end

    it "returns false if there's matching records" do
      expect(Response).to receive(:for_survey_hospital_and_year_of_registration).and_return(["something"])
      expect(CsvGenerator.new(survey.id, "", "", "")).not_to be_empty
    end
  end

  describe "Generating the CSV" do
    it "includes the correct details" do
      section2 = create(:section, survey: survey, section_order: 2)
      section1 = create(:section, survey: survey, section_order: 1)
      q_choice = create(:question, section: section1, question_order: 1, question_type: Question::TYPE_CHOICE, code: 'ChoiceQ')
      q_date = create(:question, section: section1, question_order: 3, question_type: Question::TYPE_DATE, code: 'DateQ')
      q_decimal = create(:question, section: section2, question_order: 2, question_type: Question::TYPE_DECIMAL, code: 'DecimalQ')
      q_integer = create(:question, section: section2, question_order: 1, question_type: Question::TYPE_INTEGER, code: 'IntegerQ')
      q_text = create(:question, section: section1, question_order: 2, question_type: Question::TYPE_TEXT, code: 'TextQ')
      q_time = create(:question, section: section1, question_order: 4, question_type: Question::TYPE_TIME, code: 'TimeQ')

      response1 = create(:response, hospital: create(:hospital, name: 'RNS', unit: 'IVF', site: 'HRL', site_name: 'HRL'), survey: survey, year_of_registration: 2009, baby_code: 'ABC-123')
      create(:answer, response: response1, question: q_choice, answer_value: '1')
      create(:answer, response: response1, question: q_date, answer_value: '25/02/2001')
      create(:answer, response: response1, question: q_decimal, answer_value: '15.5673')
      create(:answer, response: response1, question: q_integer, answer_value: '877')
      create(:answer, response: response1, question: q_text, answer_value: 'ABc')
      create(:answer, response: response1, question: q_time, answer_value: '14:56')
      response1.reload
      response1.save!

      response2 = create(:response, hospital: create(:hospital, name: 'RNS', unit: 'IVF', site: 'BBB', site_name: 'BBB'), survey: survey, year_of_registration: 2011, baby_code: 'DEF-567')
      create(:answer, response: response2, question: q_integer, answer_value: '99')
      create(:answer, response: response2, question: q_text, answer_value: 'ABCdefg Ijkl')
      response2.reload
      response2.save!

      expect(Response).to receive(:for_survey_hospital_and_year_of_registration).with(survey, '', '', '').and_return([response1, response2])
      csv = CsvGenerator.new(survey.id, '', '', '').csv
      expected = []
      expected << %w(TreatmentData YearOfTreatment Clinic SiteName UnitID SiteID CYCLE_ID ChoiceQ TextQ DateQ TimeQ IntegerQ DecimalQ)
      expected << ['Survey One', '2009', 'RNS', 'HRL', 0, 0, 'ABC-123', '1', 'ABc', '2001-02-25', '14:56', '877', '15.5673']
      expected << ['Survey One', '2011', 'RNS', 'BBB', 0, 0, 'DEF-567', '', 'ABCdefg Ijkl', '', '', '99', '']
      expect(CSV.parse(csv)).to eq(expected)
    end
  end

end
