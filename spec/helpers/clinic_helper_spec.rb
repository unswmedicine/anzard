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

# Specs in this file have access to a helper object that includes
# the ResponsesHelper. For example:
#
# describe ResponsesHelper, :type => :helper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end

describe ClinicsHelper, :type => :helper do
  let(:capturesystem) { create(:capturesystem, name:'ANZARD', base_url:'http://localhost:3000') }
  describe 'Returning clinic unit options' do
    it 'should return nothing when there are no existing clinics' do
      expect(helper.clinics_unit_options(capturesystem)).to eq('')
    end

    describe 'when there are existing clinics' do
      it 'should return a list of all the distinct unit options ordered by unit code' do
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 101)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Newcastle', site_code: 105)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Kent Street', site_code: 100)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Illawarra', site_code: 102)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'North Shore', site_code: 101)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'Eastern Suburbs', site_code: 107)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'Demeter Laboratories', unit_code: 109, site_name: 'Liverpool', site_code: 100)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'Monash IVF Reproductive Medicine', unit_code: 105, site_name: 'Albury', site_code: 100)
        create(:clinic, capturesystem: capturesystem, state: 'SA', unit_name: 'City Fertility Centre', unit_code: 307, site_name: 'Adelaide', site_code: 104)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'QFG', unit_code: 302, site_name: 'Mackay', site_code: 101)

        expected_options = '<option value="101">(101) IVF Australia</option>'
        expected_options += "\n" + '<option value="103">(103) Genea</option>'
        expected_options += "\n" + '<option value="105">(105) Monash IVF Reproductive Medicine</option>'
        expected_options += "\n" + '<option value="109">(109) Demeter Laboratories</option>'
        expected_options += "\n" + '<option value="302">(302) QFG</option>'
        expected_options += "\n" + '<option value="307">(307) City Fertility Centre</option>'
        expect(helper.clinics_unit_options(capturesystem)).to eq(expected_options)
      end
    end
    end

  describe 'Returning clinic unit options with new' do
    it 'should only return the "New Unit" option when there are no existing clinics' do
      expect(helper.clinics_unit_options_with_new(capturesystem)).to eq('<option value="">New Unit</option>')
    end

    describe 'when there are existing clinics' do
      it 'should return a list of all the distinct unit options ordered by unit code with a "New Unit" option prepended' do
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 101)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Newcastle', site_code: 105)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Kent Street', site_code: 100)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Illawarra', site_code: 102)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'North Shore', site_code: 101)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'Eastern Suburbs', site_code: 107)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'Demeter Laboratories', unit_code: 109, site_name: 'Liverpool', site_code: 100)
        create(:clinic, capturesystem: capturesystem, state: 'NSW', unit_name: 'Monash IVF Reproductive Medicine', unit_code: 105, site_name: 'Albury', site_code: 100)
        create(:clinic, capturesystem: capturesystem, state: 'SA', unit_name: 'City Fertility Centre', unit_code: 307, site_name: 'Adelaide', site_code: 104)
        create(:clinic, capturesystem: capturesystem, state: 'VIC', unit_name: 'QFG', unit_code: 302, site_name: 'Mackay', site_code: 101)

        expected_options = '<option value="">New Unit</option>'
        expected_options += '<option value="101">(101) IVF Australia</option>'
        expected_options += "\n" + '<option value="103">(103) Genea</option>'
        expected_options += "\n" + '<option value="105">(105) Monash IVF Reproductive Medicine</option>'
        expected_options += "\n" + '<option value="109">(109) Demeter Laboratories</option>'
        expected_options += "\n" + '<option value="302">(302) QFG</option>'
        expected_options += "\n" + '<option value="307">(307) City Fertility Centre</option>'
        expect(helper.clinics_unit_options_with_new(capturesystem)).to eq(expected_options)
      end
    end
  end
end