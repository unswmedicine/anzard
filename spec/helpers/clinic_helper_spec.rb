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
  describe 'Returning clinic unit options' do
    it 'should only return the "New Unit" option when there are no existing clinics' do
      expect(helper.clinics_unit_options).to eq('<option value="">New Unit</option>')
    end

    describe 'when there are existing clinics' do
      it 'should return a list of all the distinct unit options ordered by unit code with a "New Unit" option prepended' do
        create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 1)
        create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Newcastle', site_code: 5)
        create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Kent Street', site_code: 0)
        create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Illawarra', site_code: 2)
        create(:clinic, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'North Shore', site_code: 1)
        create(:clinic, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'Eastern Suburbs', site_code: 7)
        create(:clinic, state: 'NSW', unit_name: 'Demeter Laboratories', unit_code: 109, site_name: 'Liverpool', site_code: 0)
        create(:clinic, state: 'NSW', unit_name: 'Monash IVF Reproductive Medicine', unit_code: 105, site_name: 'Albury', site_code: 0)
        create(:clinic, state: 'SA', unit_name: 'City Fertility Centre', unit_code: 307, site_name: 'Adelaide', site_code: 4)
        create(:clinic, state: 'VIC', unit_name: 'QFG', unit_code: 302, site_name: 'Mackay', site_code: 1)

        expected_options = '<option value="">New Unit</option>'
        expected_options += '<option value="101">(101) IVF Australia</option>'
        expected_options += "\n" + '<option value="103">(103) Genea</option>'
        expected_options += "\n" + '<option value="105">(105) Monash IVF Reproductive Medicine</option>'
        expected_options += "\n" + '<option value="109">(109) Demeter Laboratories</option>'
        expected_options += "\n" + '<option value="302">(302) QFG</option>'
        expected_options += "\n" + '<option value="307">(307) City Fertility Centre</option>'
        expect(helper.clinics_unit_options).to eq(expected_options)
      end
    end
  end
end