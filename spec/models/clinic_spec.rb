require 'rails_helper'


describe Clinic do
  describe "Associations" do
    it { should have_many(:clinic_allocations)}
    it { should have_many(:users).through(:clinic_allocations) }
    it { should have_many(:responses) }
  end

  describe "Validations" do
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:unit_name) }
    it { should validate_presence_of(:unit_code) }
    it { should validate_presence_of(:site_name) }
    it { should validate_presence_of(:site_code) }

    it { should validate_uniqueness_of(:site_code).scoped_to(:unit_code) }
  end

  describe "Grouping Clinics By State" do
    it "should put the states in alphabetic order then the clinics under then in alphabetic order of unit name" do
      demeter = create(:clinic, state: "NSW", unit_name: "Demeter Laboratories").id
      genea = create(:clinic, state: "Vic", unit_name: "Genea").id
      ivf_aus = create(:clinic, state: "NSW", unit_name: "IVF Australia").id
      monash_ivf = create(:clinic, state: "NSW", unit_name: "Monash IVF Reproductive Medicine").id
      qfg = create(:clinic, state: "Vic", unit_name: "QFG").id
      city_fertility = create(:clinic, state: "SA", unit_name: "City Fertility Centre").id

      output = Clinic.clinics_by_state
      output.size.should eq(3)
      output[0][0].should eq("NSW")
      output[1][0].should eq("SA")
      output[2][0].should eq("Vic")

      output[0][1].should eq([["Demeter Laboratories", demeter], ["IVF Australia", ivf_aus], ["Monash IVF Reproductive Medicine", monash_ivf]])
      output[1][1].should eq([["City Fertility Centre", city_fertility]])
      output[2][1].should eq([["Genea", genea], ["QFG", qfg]])
    end
  end

  describe 'Display formats' do
    before :each do
      @clinic = create(:clinic, state: 'NSW', unit_code: 101, unit_name: 'IVF Australia', site_code: 1, site_name: 'North Shore')
    end

    it 'should display unit_name_with_code as unit code in brackets followed by the unit name' do
      expect(@clinic.unit_name_with_code).to eq('(101) IVF Australia')
    end

    it 'shuold display site_name_with_code as site code in brackets followed by the site name' do
      expect(@clinic.site_name_with_code).to eq('(1) North Shore')
    end

    it 'should display site_name_with_full_code as the unit code and site code in brackets separated by a hypen follwed by the site name' do
      expect(@clinic.site_name_with_full_code).to eq('(101-1) North Shore')
    end
  end

  describe 'clinics_with_unit_code' do
    it 'should return all clinics with the matching unit code' do
      c1_1 = create(:clinic, state: 'NSW', unit_code: 101, unit_name: 'IVF Australia', site_code: 1, site_name: 'North Shore')
      c1_2 = create(:clinic, state: 'ACT', unit_code: 101, unit_name: 'IVF Australia', site_code: 7, site_name: 'Eastern Suburbs')
      c2_1 = create(:clinic, state: 'NSW', unit_code: 103, unit_name: 'Genea', site_code: 6, site_name: 'Liverpool')
      c2_2 = create(:clinic, state: 'NSW', unit_code: 103, unit_name: 'Genea', site_code: 4, site_name: 'RPAH')
      c3 = create(:clinic, state: 'QLD', unit_code: 312, unit_name: 'Cairns Fertility Centre', site_code: 0, site_name: 'Cairns')
      expect(Clinic.clinics_with_unit_code(101)).to eq([c1_1, c1_2])
      expect(Clinic.clinics_with_unit_code(103)).to eq([c2_1, c2_2])
      expect(Clinic.clinics_with_unit_code(312)).to eq([c3])
      expect(Clinic.clinics_with_unit_code(456)).to eq([])
    end
  end

end
