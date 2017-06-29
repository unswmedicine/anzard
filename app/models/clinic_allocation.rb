class ClinicAllocation < ApplicationRecord

  belongs_to :user
  belongs_to :clinic

  validates_presence_of :user_id
  validates_presence_of :clinic_id
  validates_uniqueness_of :user_id, scope: :clinic_id, message: 'has already been added to specified Clinic' # Each allocation should be unique
  validate :user_can_only_be_allocated_to_one_clinic_unit

  def user_can_only_be_allocated_to_one_clinic_unit
    preexisting_allocation = ClinicAllocation.find_by(user_id: user_id)
    unless preexisting_allocation.nil? || preexisting_allocation.clinic.nil? # preexisting allocation clinic shouldn't ever be nil outside of testing
      if preexisting_allocation.clinic.unit_code != clinic.unit_code
        errors.add(:clinic_id, "User is already allocated to clinic unit_code #{preexisting_allocation.clinic.unit_code}")
      end
    end
  end

end