class ClinicAllocation < ApplicationRecord

  belongs_to :user
  belongs_to :clinic

  validates_presence_of :user, :user_id
  validates_presence_of :clinic, :clinic_id
  validates_uniqueness_of :user_id, scope: :clinic_id, message: 'has already been added to specified Clinic' # Each allocation should be unique

  validate :user_can_only_be_allocated_to_one_clinic_unit

  after_validation :allocate_clinic_unit_code_to_user

  def user_can_only_be_allocated_to_one_clinic_unit
    unless user.nil? # User is only nil during RSpec test setup (this should be fine since we validate presence)
      if !user.allocated_unit_code.nil? && user.allocated_unit_code != clinic.unit_code
        errors.add(:clinic_id, "User is already allocated to clinic unit_code #{user.allocated_unit_code}")
      end
    end
  end

  private

  def allocate_clinic_unit_code_to_user
    unless user.nil? # User is only nil during RSpec test setup (this should be fine since we validate presence)
      user.allocated_unit_code = clinic.unit_code if user.allocated_unit_code.nil?
    end
  end

end