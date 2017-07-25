require 'rails_helper'

describe ClinicAllocation do

  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:clinic) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:clinic) }
    it { should validate_presence_of(:clinic_id) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:clinic_id).with_message('has already been added to specified Clinic') }

    describe 'user can only be allocated to clinics within same unit' do
      it 'should allow a user to be associated with a clinic' do
        allocation = create(:clinic_allocation, user: create(:user), clinic: create(:clinic))
        expect(allocation).to be_valid
      end

      it 'should allow a user to be associated with multiple clinics within the same unit' do
        user = create(:user)
        clinic1 = create(:clinic, unit_code: 100, site_code: 101, unit_name: 'unit 100', site_name: 'site 101')
        clinic2 = create(:clinic, unit_code: 100, site_code: 102, unit_name: 'unit 100', site_name: 'site 102')
        allocation1 = create(:clinic_allocation, user: user, clinic: clinic1)
        expect(allocation1).to be_valid

        allocation2 = build(:clinic_allocation, user: user, clinic: clinic2)
        expect(allocation2).to be_valid
      end

      it 'should not allow a user to be associated with multiple clinics from different units' do
        user = create(:user)
        clinic1 = create(:clinic, unit_code: 100, site_code: 101, unit_name: 'unit 100', site_name: 'site 101')
        allocation1 = create(:clinic_allocation, user: user, clinic: clinic1)
        expect(allocation1).to be_valid

        clinic2 = create(:clinic, unit_code: 200, site_code: 101, unit_name: 'unit 200', site_name: 'site 101')
        allocation2 = build(:clinic_allocation, user: user, clinic: clinic2)
        expect(allocation2).to_not be_valid
        expect(allocation2.errors[:id]).to eq(['User is already allocated to clinic unit_code 100'])
      end
    end

    it 'should not allow a user to have all of their associations with one unit removed and added to a new unit' do
      user = create(:user)
      clinic1 = create(:clinic, unit_code: 100, site_code: 101, unit_name: 'unit 100', site_name: 'site 101')
      allocation1 = create(:clinic_allocation, user: user, clinic: clinic1)
      expect(allocation1).to be_valid
      allocation1.delete

      clinic2 = create(:clinic, unit_code: 200, site_code: 101, unit_name: 'unit 200', site_name: 'site 101')
      allocation2 = build(:clinic_allocation, user: user, clinic: clinic2)
      expect(allocation2).to_not be_valid
      expect(allocation2.errors[:id]).to eq(['User is already allocated to clinic unit_code 100'])
    end
  end

  describe 'allocate clinic unit code to user' do
    it 'should allocate the clinic unit code to the user if previously nil' do
      user = create(:user)
      clinic = create(:clinic, unit_code: 100, site_code: 101, unit_name: 'unit 100', site_name: 'site 101')
      create(:clinic_allocation, user: user, clinic: clinic)
      expect(user.allocated_unit_code).to eq(100)
    end

    it 'should not overwrite any existing user clinic unit code allocation' do
      user = create(:user)
      clinic1 = create(:clinic, unit_code: 100, site_code: 101, unit_name: 'unit 100', site_name: 'site 101')
      create(:clinic_allocation, user: user, clinic: clinic1)
      expect(user.allocated_unit_code).to eq(100)

      clinic2 = create(:clinic, unit_code: 200, site_code: 101, unit_name: 'unit 200', site_name: 'site 101')
      allocation2 = build(:clinic_allocation, user: user, clinic: clinic2)
      expect(allocation2).to_not be_valid
      expect(allocation2.errors[:id]).to eq(['User is already allocated to clinic unit_code 100'])
      expect(user.allocated_unit_code).to eq(100)
    end
  end

  describe 'clinic activation status' do
    it 'should be able to allocate a user to an active clinic' do
      user = create :user
      clinic = create :clinic
      allocation = build :clinic_allocation, user: user, clinic: clinic
      expect(allocation).to be_valid
    end

    it 'should not be possible to allocate a user to a deactivated clinic' do
      user = create :user
      clinic = create :clinic, active: false
      allocation = build :clinic_allocation, user: user, clinic: clinic
      expect(allocation).to_not be_valid
      expect(allocation.errors[:id]).to eq(['User cannot be allocated to a deactivated clinic'])
    end
  end
end