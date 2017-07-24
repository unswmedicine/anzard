require 'rails_helper'

describe Clinic do
  describe 'Associations' do
    it { should have_many(:clinic_allocations)}
    it { should have_many(:users).through(:clinic_allocations) }
    it { should have_many(:responses) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:unit_name) }
    it { should validate_presence_of(:unit_code) }
    it { should validate_presence_of(:site_name) }
    it { should validate_presence_of(:site_code) }
    it { should validate_inclusion_of(:active).in_array([true, false]) }

    it { should validate_uniqueness_of(:site_code).scoped_to(:unit_code) }
    it { should validate_numericality_of(:unit_code).is_greater_than_or_equal_to(100).is_less_than_or_equal_to(999) }
    it { should validate_numericality_of(:site_code).is_greater_than_or_equal_to(100).is_less_than_or_equal_to(999) }

    it { should validate_inclusion_of(:state).in_array(Clinic::PERMITTED_STATES).with_message("must be one of #{Clinic::PERMITTED_STATES.to_s}")}

    describe 'no unit duplication' do
      it 'should allow creation of clinics from different units' do
        create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 101)
        clinic = build(:clinic, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'North Shore', site_code: 101)
        expect(clinic).to be_valid
      end

      it 'should allow creation of clinics from the same unit' do
        create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 101)
        clinic = build(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Newcastle', site_code: 105)
        expect(clinic).to be_valid
      end

      it 'should not allow creation of clinics that have the same unit code but different unit name' do
        create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 101)
        clinic = build(:clinic, state: 'VIC', unit_name: 'Genea typo', unit_code: 103, site_name: 'Newcastle', site_code: 105)
        expect(clinic).to_not be_valid
        expect(clinic.errors[:clinic_id]).to eq(['already exists with that Unit Code under a different Unit Name'])
      end
    end
  end

  describe 'Permitted States' do
    it 'should only allow Australian states and New Zealand' do
      expect(Clinic::PERMITTED_STATES).to eq(%w(ACT NSW NT QLD SA TAS VIC WA NZ))
    end
  end

  describe 'Grouping of Clinics' do
    before :each do
      @genea_1 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 101)
      @genea_2 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Newcastle', site_code: 105)
      @genea_3 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Kent Street', site_code: 100)
      @genea_4 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Illawarra', site_code: 102)

      @ivf_aus_1 = create(:clinic, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'North Shore', site_code: 101)
      @ivf_aus_2 = create(:clinic, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'Eastern Suburbs', site_code: 107)

      @demeter = create(:clinic, state: 'NSW', unit_name: 'Demeter Laboratories', unit_code: 109, site_name: 'Liverpool', site_code: 100)
      @monash_ivf = create(:clinic, state: 'NSW', unit_name: 'Monash IVF Reproductive Medicine', unit_code: 105, site_name: 'Albury', site_code: 100)
      @qfg = create(:clinic, state: 'VIC', unit_name: 'QFG', unit_code: 302, site_name: 'Mackay', site_code: 101)
      @city_fertility = create(:clinic, state: 'SA', unit_name: 'City Fertility Centre', unit_code: 307, site_name: 'Adelaide', site_code: 104)
    end

    describe 'Grouping of Clinics by State with Site Name' do
      it 'should group the clinics by state and then order the clinics alphabetically by state, then unit name, then site name' do
        output = Clinic.clinics_by_state_with_clinic_id
        expect(output.size).to eq(3)
        expect(output[0][0]).to eq('NSW')
        expect(output[1][0]).to eq('SA')
        expect(output[2][0]).to eq('VIC')

        expect(output[0][1]).to eq([['Demeter Laboratories - Liverpool', @demeter.id], ['IVF Australia - Eastern Suburbs', @ivf_aus_2.id], ['IVF Australia - North Shore', @ivf_aus_1.id], ['Monash IVF Reproductive Medicine - Albury', @monash_ivf.id]])
        expect(output[1][1]).to eq([['City Fertility Centre - Adelaide', @city_fertility.id]])
        expect(output[2][1]).to eq([['Genea - Coffs Harbour', @genea_1.id], ['Genea - Illawarra', @genea_4.id], ['Genea - Kent Street', @genea_3.id], ['Genea - Newcastle', @genea_2.id], ['QFG - Mackay', @qfg.id]])
      end
    end

    describe 'Grouping of Clinics by State and unique by Unit' do
      it 'should group the clinics by state and then order the clinics alphabetically by state, then unit name, where each unit name is only displayed once' do
        output = Clinic.units_by_state_with_unit_code
        expect(output.size).to eq(3)
        expect(output[0][0]).to eq('NSW')
        expect(output[1][0]).to eq('SA')
        expect(output[2][0]).to eq('VIC')

        expect(output[0][1]).to eq([['Demeter Laboratories (109)', 109], ['IVF Australia (101)', 101], ['Monash IVF Reproductive Medicine (105)', 105]])
        expect(output[1][1]).to eq([['City Fertility Centre (307)', 307]])
        expect(output[2][1]).to eq([['Genea (103)', 103], ['QFG (302)', 302]])
      end
    end
  end

  describe 'Retrieving of Units' do
    before :each do
      @genea_1 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Coffs Harbour', site_code: 101)
      @genea_2 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Newcastle', site_code: 105)
      @genea_3 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Kent Street', site_code: 100)
      @genea_4 = create(:clinic, state: 'VIC', unit_name: 'Genea', unit_code: 103, site_name: 'Illawarra', site_code: 102)

      @ivf_aus_1 = create(:clinic, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'North Shore', site_code: 101)
      @ivf_aus_2 = create(:clinic, state: 'NSW', unit_name: 'IVF Australia', unit_code: 101, site_name: 'Eastern Suburbs', site_code: 107)

      @demeter = create(:clinic, state: 'NSW', unit_name: 'Demeter Laboratories', unit_code: 109, site_name: 'Liverpool', site_code: 100)
      @monash_ivf = create(:clinic, state: 'NSW', unit_name: 'Monash IVF Reproductive Medicine', unit_code: 105, site_name: 'Albury', site_code: 100)
      @qfg = create(:clinic, state: 'VIC', unit_name: 'QFG', unit_code: 302, site_name: 'Mackay', site_code: 101)
      @city_fertility = create(:clinic, state: 'SA', unit_name: 'City Fertility Centre', unit_code: 307, site_name: 'Adelaide', site_code: 104)
    end

    it 'should return a set of all unique pairs of Unit Codes and Unit Names in the system' do
      output = Clinic.distinct_unit_list
      expect(output.size).to eq(6)
      expect(output).to eq([{unit_code: 101, unit_name: 'IVF Australia'}, {unit_code: 103, unit_name: 'Genea'},
                            {unit_code: 105, unit_name: 'Monash IVF Reproductive Medicine'},
                            {unit_code: 109, unit_name: 'Demeter Laboratories'}, {unit_code: 302, unit_name: 'QFG'},
                            {unit_code: 307, unit_name: 'City Fertility Centre'}])
    end
  end

  describe 'Display formats' do
    before :each do
      @clinic = create(:clinic, state: 'NSW', unit_code: 101, unit_name: 'IVF Australia', site_code: 101, site_name: 'North Shore')
    end

    it 'should display unit_site_code as unit code and site code in brackets separated by a hyphen' do
      expect(@clinic.unit_site_code).to eq('(101-101)')
    end

    it 'should display unit_name_with_code as unit code in brackets followed by the unit name' do
      expect(@clinic.unit_name_with_code).to eq('(101) IVF Australia')
    end

    it 'should display unit_name_with_code_for_unit as unit code in brackets followed by the unit name' do
      expect(Clinic.unit_name_with_code_for_unit(101)).to eq('(101) IVF Australia')
    end

    it 'should display site_name_with_code as site code in brackets followed by the site name' do
      expect(@clinic.site_name_with_code).to eq('(101) North Shore')
    end

    it 'should display site_name_with_full_code as the unit code and site code in brackets separated by a hypen follwed by the site name' do
      expect(@clinic.site_name_with_full_code).to eq('(101-101) North Shore')
    end
  end

  describe 'Clinics with Unit Code' do
    before :each do
      @c1_1 = create(:clinic, state: 'NSW', unit_code: 501, unit_name: 'IVF Australia', site_code: 113, site_name: 'North Shore')
      @c1_2 = create(:clinic, state: 'ACT', unit_code: 501, unit_name: 'IVF Australia', site_code: 127, site_name: 'Eastern Suburbs')
      @c2_1 = create(:clinic, state: 'NSW', unit_code: 503, unit_name: 'Genea', site_code: 161, site_name: 'Liverpool')
      @c2_2 = create(:clinic, state: 'NSW', unit_code: 503, unit_name: 'Genea', site_code: 143, site_name: 'RPAH')
      @c3 = create(:clinic, state: 'QLD', unit_code: 512, unit_name: 'Cairns Fertility Centre', site_code: 120, site_name: 'Cairns')
    end

    it 'should return all clinics with the matching unit code ordered by site code' do
      expect(Clinic.clinics_with_unit_code(501)).to eq([@c1_1, @c1_2])
      expect(Clinic.clinics_with_unit_code(503)).to eq([@c2_2, @c2_1])
      expect(Clinic.clinics_with_unit_code(512)).to eq([@c3])
      expect(Clinic.clinics_with_unit_code(456)).to eq([])
    end

    it 'should exclusively return active clinics only when specified' do
      @c1_2.update!(active: false)
      create(:clinic, state: 'NSW', unit_code: 501, unit_name: 'IVF Australia', site_code: 116, site_name: 'Hunter IVF', active: false)
      expect(Clinic.clinics_with_unit_code(501, true)).to eq([@c1_1])
      expect(Clinic.clinics_with_unit_code(503, true)).to eq([@c2_2, @c2_1])
      expect(Clinic.clinics_with_unit_code(512, true)).to eq([@c3])
      expect(Clinic.clinics_with_unit_code(456, true)).to eq([])
    end
  end

  describe 'Activate clinic' do
    it 'should update the clinic active attribute to true' do
      clinic = create(:clinic, active: false)
      expect(clinic.active).to eq(false)
      clinic.activate
      expect(clinic.active).to eq(true)
    end
  end

  describe 'Deactivate clinic' do
    it 'should update the clinic active attribute to false' do
      clinic = create(:clinic)
      expect(clinic.active).to eq(true)
      clinic.deactivate
      expect(clinic.active).to eq(false)
    end
  end

end
