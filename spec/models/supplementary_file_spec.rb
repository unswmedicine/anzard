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

describe SupplementaryFile do
  describe "Associations" do
    it { should belong_to(:batch_file) }
  end

  describe "Validations" do
    it { should validate_presence_of(:multi_name) }
  end
  
  describe "Validate file" do
    it "should reject binary files such as xls" do
      supplementary_file = create_supplementary_file('not_csv.xls', 'my multi')
      supplementary_file.pre_process.should be false
      supplementary_file.message.should eq("The supplementary file you uploaded for 'my multi' was not a valid CSV file.")
    end

    it "should reject files that are text but have malformed csv" do
      supplementary_file = create_supplementary_file('invalid_csv.csv', 'my multi')
      supplementary_file.pre_process.should be false
      supplementary_file.message.should eq("The supplementary file you uploaded for 'my multi' was not a valid CSV file.")
    end

    it "should reject file without a cycle id column" do
      supplementary_file = create_supplementary_file('no_cycle_id_column.csv', 'my multi')
      supplementary_file.pre_process.should be false
      supplementary_file.message.should eq("The supplementary file you uploaded for 'my multi' did not contain a CYCLE_ID column.")
    end

    it "should reject files that are empty" do
      # Expect the processing of the empty file to return exception during tests, which is otherwise caught and displayed in the controller.
      # This exception is raised because the PaperClip gem determines that the empty CSV is a spoofing attempt.
      expect {
        supplementary_file = create_supplementary_file('empty.csv', 'my multi')
        supplementary_file.pre_process.should be false
        supplementary_file.message.should eq("The supplementary file you uploaded for 'my multi' did not contain any data.")
      }.to raise_error ActiveRecord::RecordInvalid, 'Validation failed: File has contents that are not what they are reported to be'
    end

    it "should reject files that have a header row only" do
      supplementary_file = create_supplementary_file('headers_only.csv', 'my multi')
      supplementary_file.pre_process.should be false
      supplementary_file.message.should eq("The supplementary file you uploaded for 'my multi' did not contain any data.")
    end
  end

  describe "Denormalise file" do
    it "should take the rows from the file and stich them together as denormalised answers" do
      # this is a bit hard to express, so commenting for clarity.
      # what we're doing is taking a normalised set of answers and rearranging them to be de-normalised to suit the structure we have
      # e.g. a CSV would contain
      # | CycleID | SurgeryDate | SurgeryName  |
      # | B1       | 2012-12-1   | blah1        |
      # | B1       | 2012-12-2   | blah2        |
      # | B2       | 2012-12-1   | blah1        |
      # | B2       | 2012-12-2   | blah2        |
      # | B2       | 2012-12-3   | blah3        |
      # and we want to turn that into something like this
      # | CycleID | SurgeryDate1 | SurgeryName1  | SurgeryDate2 | SurgeryName2  | SurgeryDate3 | SurgeryName3 |
      # | B1       | 2012-12-1    | blah1         |2012-12-2     | blah2         |              |              |
      # | B2       | 2012-12-1    | blah1         |2012-12-2     | blah2         |2012-12-3     | blah3        |

      file = Rack::Test::UploadedFile.new('test_data/survey/batch_files/batch_sample_multi1.csv', 'text/csv')
      supp_file = create(:supplementary_file, multi_name: 'xyz', file: file)
      supp_file.pre_process.should be true

      denormalised = supp_file.as_denormalised_hash
      #File contents:
      #UNIT, SITE, CycleID,Date,Time
      #100,100,B1,2012-12-01,11:45
      #100,100,B1,2011-11-01,
      #100,100,B2,2011-08-30,01:05
      #100,100,B2,2010-03-04,13:23
      #100,100,B2,,11:53
      denormalised.size.should eq(2)
      cycle1 = denormalised['B1']
      cycle1.should eq({'UNIT1'=>'100', 'SITE1'=>'100', 'UNIT2'=>'100', 'SITE2'=>'100', 'Date1' => '2012-12-01', 'Date2' => '2011-11-01', 'Time1' => '11:45'})
      cycle2 = denormalised['B2']
      cycle2.should eq({'UNIT1'=>'100', 'SITE1'=>'100', 'UNIT2'=>'100', 'SITE2'=>'100', 'UNIT3'=>'100', 'SITE3'=>'100', 'Date1' => '2011-08-30', 'Date2' => '2010-03-04', 'Time1' => '01:05', 'Time2' => '13:23', 'Time3' => '11:53'})
    end
  end
  
  def create_supplementary_file(filename, multi_name)
    file = Rack::Test::UploadedFile.new('test_data/survey/batch_files/' + filename, 'text/csv')
    create(:supplementary_file, multi_name: multi_name, file: file)
  end
end
