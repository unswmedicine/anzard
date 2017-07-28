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

class ClinicAllocation < ApplicationRecord

  belongs_to :user
  belongs_to :clinic

  validates_presence_of :user
  validates_presence_of :clinic, :clinic_id
  validates_uniqueness_of :user_id, scope: :clinic_id, message: 'has already been added to specified Clinic' # Each allocation should be unique

  validate :user_can_only_be_allocated_to_one_clinic_unit

  validate :user_cannot_be_allocated_to_deactivated_clinic

  after_validation :allocate_clinic_unit_code_to_user

  def user_can_only_be_allocated_to_one_clinic_unit
    unless user.nil? # User is only nil during RSpec test setup (this should be fine since we validate presence)
      if !user.allocated_unit_code.nil? && user.allocated_unit_code != clinic.unit_code
        errors.add(:id, "User is already allocated to clinic unit_code #{user.allocated_unit_code}")
      end
    end
  end

  def user_cannot_be_allocated_to_deactivated_clinic
    unless user.nil? # User is only nil during RSpec test setup (this should be fine since we validate presence)
      errors.add(:id, 'User cannot be allocated to a deactivated clinic') unless clinic.active
    end
  end

  private

  def allocate_clinic_unit_code_to_user
    unless user.nil? # User is only nil during RSpec test setup (this should be fine since we validate presence)
      user.allocated_unit_code = clinic.unit_code if user.allocated_unit_code.nil?
    end
  end

end