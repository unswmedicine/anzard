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

class Clinic < ApplicationRecord

  SITE_CODE_MAX_SIZE = 3

  has_many :clinic_allocations
  has_many :users, through: :clinic_allocations
  has_many :responses

  validates_presence_of :unit_code
  validates_presence_of :unit_name
  validates_presence_of :site_code
  validates_presence_of :site_name
  validates_presence_of :state

  validates_inclusion_of :active, in: [true, false]

  validates_uniqueness_of :site_code, scope: :unit_code
  validates_numericality_of :unit_code, greater_than_or_equal_to: 100, less_than_or_equal_to: 999
  validates_numericality_of :site_code, greater_than_or_equal_to: 100, less_than_or_equal_to: 999

  PERMITTED_STATES = %w(ACT NSW NT QLD SA TAS VIC WA NZ)
  validates_inclusion_of :state, in: PERMITTED_STATES, message: "must be one of #{PERMITTED_STATES.to_s}"

  validate :no_unit_with_same_code_and_different_name

  def no_unit_with_same_code_and_different_name
    units_with_same_code_and_different_name = Clinic.where(unit_code: unit_code).where.not(unit_name: unit_name)
    if units_with_same_code_and_different_name.count > 0
      errors.add(:clinic_id, 'already exists with that Unit Code under a different Unit Name')
    end
  end

  GROUP_BY_STATE_WITH_CLINIC = 0
  GROUP_BY_STATE_WITH_UNIT = 1

  def activate
    self.update!(active: true)
  end

  def deactivate
    self.update!(active: false)
  end

  def unit_site_code
    "(#{unit_code}-#{site_code})"
  end

  def unit_name_with_code
    "(#{unit_code}) #{unit_name}"
  end

  def site_name_with_code
    "(#{site_code}) #{site_name}"
  end

  def site_name_with_full_code
    "(#{unit_code}-#{site_code}) #{site_name}"
  end

  def self.unit_name_with_code_for_unit(unit_code)
    clinic = find_by(unit_code: unit_code)
    clinic.unit_name_with_code
  end

  def self.clinics_with_unit_code(unit_code, only_active_clinics=false)
    if only_active_clinics
      clinics = where(unit_code: unit_code, active: true)
    else
      clinics = where(unit_code: unit_code)
    end
    clinics.order(:site_code)
  end

  # Returns all Clinics grouped by State in the format [[State], [Unit Name - Site Name', Clinic_id_1], [Unit Name - Site Name', Clinic_id_2], ...]
  def self.clinics_by_state_with_clinic_id
    group_clinics(GROUP_BY_STATE_WITH_CLINIC)
  end

  # Returns all Units grouped by State in the format [[State], [Unit Name (Unit Code)', Clinic_1_unit_code], [Unit Name - Site Name', Clinic_id_2_unit_code], ...]
  def self.units_by_state_with_unit_code
    group_clinics(GROUP_BY_STATE_WITH_UNIT)
  end

  # Returns a list of all distinct Units, ordered by unit code
  def self.distinct_unit_list
    units = order(:unit_code).pluck('DISTINCT unit_code, unit_name')
    units.map{ |code, name| {unit_code: code, unit_name: name}}
  end

  private

  def self.group_clinics(grouping_type=GROUP_BY_STATE_WITH_CLINIC)
    clinics = order(:unit_name, :site_name).all
    grouped = clinics.group_by(&:state)

    if grouping_type == GROUP_BY_STATE_WITH_CLINIC
      output = grouped.collect { |state, clinics| [state, clinics.collect { |h| [h.site_name.blank? ?  h.unit_name : h.unit_name + ' - ' + h.site_name, h.id] }] }
    elsif grouping_type == GROUP_BY_STATE_WITH_UNIT
      output = grouped.collect { |state, clinics| [state, clinics.collect { |h| [h.unit_name + ' (' + h.unit_code.to_s + ')', h.unit_code] }] }
    end

    output.each do |key, value|
      value.uniq!
    end
    output.sort { |a, b| a[0] <=> b[0] }
  end


end
