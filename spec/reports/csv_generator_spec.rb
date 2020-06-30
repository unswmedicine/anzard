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

describe CsvGenerator do
  let(:capturesystem) { create(:capturesystem, name:'ANZARD', base_url:'http://localhost:3000') }
  let(:survey) { create(:survey, name: "Survey One") }
  let(:clinic) { create(:clinic, unit_name: "Royal North Shore", unit_code: 100, site_name: 'Kent Street', site_code: 102, capturesystem_id: capturesystem.id ) }
  let(:clinic2) { create(:clinic, unit_name: "Royal North Shore", unit_code: 100, site_name: 'George Street', site_code: 103, capturesystem_id: capturesystem.id) }
  let(:prepend_columns) { ['TREATMENT_DATA', 'YEAR_OF_TREATMENT', "#{capturesystem.name}_Unit_Name", 'ART_Unit_Name', 'CYCLE_ID'] }

  describe "Generating the filename" do

    it "includes only survey name when no clinic or year of registration" do
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)
      expect(CsvGenerator.new(survey, "", "", "", prepend_columns).csv_filename).to eq("survey_one.csv")
    end

    it "includes survey name and clinic unit name when clinic unit set" do
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)
      expect(CsvGenerator.new(survey, clinic.unit_code, "", "", prepend_columns).csv_filename).to eq("survey_one_royal_north_shore.csv")
    end

    it "includes survey name and clinic unit and site name when clinic unit and site set" do
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)
      expect(CsvGenerator.new(survey, clinic.unit_code, clinic.site_code, "", prepend_columns).csv_filename).to eq("survey_one_royal_north_shore_kent_street.csv")
    end

    it "includes survey name and year of registration when year of registration set" do
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)
      expect(CsvGenerator.new(survey, "", "", "2009", prepend_columns).csv_filename).to eq("survey_one_2009.csv")
    end

    it "includes survey name, clinic and year of registration when all are set" do
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)
      expect(CsvGenerator.new(survey, clinic2.unit_code, clinic2.site_code, "2009", prepend_columns).csv_filename).to eq("survey_one_royal_north_shore_george_street_2009.csv")
    end

    it "makes the survey name safe for use in a filename" do
      survey = create(:survey, name: "SurVey %/\#.()A,|")
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)
      expect(CsvGenerator.new(survey, "", "", "", prepend_columns).csv_filename).to eq("survey_a.csv")
    end
  end

  describe "Checking for emptiness" do
    it "returns true if there's no matching records" do
      #expect(Response).to receive(:for_survey_clinic_and_year_of_registration).with(survey, clinic.unit_code, clinic.site_code, '2009').and_return([])
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)
      expect(Response.for_survey_clinic_and_year_of_registration(survey, clinic.unit_code, clinic.site_code, '2009')).to be_empty
      expect(CsvGenerator.new(survey, clinic.unit_code, clinic.site_code, '2009', prepend_columns)).to be_empty
    end

    it "returns false if there's matching records" do
      #expect(Response).to receive(:for_survey_clinic_and_year_of_registration).and_return(["something"])
      #expect(CsvGenerator.new(survey, "", "", "", prepend_columns)).not_to be_empty
      #coverred by the a ses below ..
    end
  end

  describe "Generating the CSV" do
    it "includes the correct details" do
      capturesystem_survey = create(:capturesystem_survey, capturesystem_id:capturesystem.id, survey_id:survey.id)

      section2 = create(:section, survey: survey, section_order: 2)
      section1 = create(:section, survey: survey, section_order: 1)
      q_choice = create(:question, section: section1, question_order: 1, question_type: Question::TYPE_CHOICE, code: 'ChoiceQ')
      q_date = create(:question, section: section1, question_order: 3, question_type: Question::TYPE_DATE, code: 'DateQ')
      q_decimal = create(:question, section: section2, question_order: 2, question_type: Question::TYPE_DECIMAL, code: 'DecimalQ')
      q_integer = create(:question, section: section2, question_order: 1, question_type: Question::TYPE_INTEGER, code: 'IntegerQ')
      q_text = create(:question, section: section1, question_order: 2, question_type: Question::TYPE_TEXT, code: 'TextQ')
      q_time = create(:question, section: section1, question_order: 4, question_type: Question::TYPE_TIME, code: 'TimeQ')

      response1 = create(:response, clinic: create(:clinic, unit_name: 'RNS IVF', unit_code: 112, site_code: 104, site_name: 'site one'), survey: survey, year_of_registration: 2009, cycle_id: 'DEF-567')
      create(:answer, response: response1, question: q_choice, answer_value: '1')
      create(:answer, response: response1, question: q_date, answer_value: '25/02/2001')
      create(:answer, response: response1, question: q_decimal, answer_value: '15.5673')
      create(:answer, response: response1, question: q_integer, answer_value: '877')
      create(:answer, response: response1, question: q_text, answer_value: 'ABc')
      create(:answer, response: response1, question: q_time, answer_value: '14:56')
      response1.reload
      response1.submitted_status=Response::STATUS_SUBMITTED
      response1.save!

      response2 = create(:response, clinic: create(:clinic, unit_name: 'RNS IVF', unit_code: 112, site_code: 106, site_name: 'site two'), survey: survey, year_of_registration: 2011, cycle_id: 'ABC-123')
      create(:answer, response: response2, question: q_integer, answer_value: '99')
      create(:answer, response: response2, question: q_text, answer_value: 'ABCdefg Ijkl')
      response2.reload
      response2.submitted_status=Response::STATUS_SUBMITTED
      response2.save!

      #expect(Response).to receive(:for_survey_clinic_and_year_of_registration).with(survey, '', '', '').and_return([response1, response2])
      expect(Response.for_survey_clinic_and_year_of_registration(survey, '', '', '')).to match_array([response1, response2])
      csv = CsvGenerator.new(survey, '', '', '', prepend_columns).csv
      csv_enumerated = CsvGenerator.new(survey, '', '', '', prepend_columns).csv_enumerator.collect {|r| r.parse_csv }
      expected = []
      expected << (prepend_columns + ['ChoiceQ', 'TextQ', 'DateQ', 'TimeQ', 'IntegerQ', 'DecimalQ'])
      #expected << ['Survey One', '2009', 'RNS IVF', 'site one', '112', '104', 'ABC-123', '1', 'ABc', '2001-02-25', '14:56', '877', '15.5673']
      #expected << ['Survey One', '2011', 'RNS IVF', 'site two', '112', '106', 'DEF-567', '', 'ABCdefg Ijkl', '', '', '99', '']
      expected << ['Survey One', '2011', 'RNS IVF', 'site two', 'ABC-123', '', 'ABCdefg Ijkl', '', '', '99', '']
      expected << ['Survey One', '2009', 'RNS IVF', 'site one', 'DEF-567', '1', 'ABc', '2001-02-25', '14:56', '877', '15.5673']
      expect(CSV.parse(csv)).to eq(expected)
      expect(csv_enumerated).to eq(expected)
    end
  end

end
