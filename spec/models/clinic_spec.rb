require 'rails_helper'


describe Clinic do
  describe "Associations" do
    it { should have_many(:users) }
    it { should have_many(:responses) }
  end

  describe "Validations" do
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:unit_name) }
    it { should validate_presence_of(:unit_code) }
    # it { should validate_presence_of(:site_name) }
    it { should validate_presence_of(:site_code) }
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


end
