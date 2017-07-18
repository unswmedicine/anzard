class Clinic < ApplicationRecord

  has_many :clinic_allocations
  has_many :users, through: :clinic_allocations
  has_many :responses

  validates_presence_of :unit_code
  validates_presence_of :unit_name
  validates_presence_of :site_code
  validates_presence_of :site_name
  validates_presence_of :state

  validates_uniqueness_of :site_code, scope: :unit_code
  validates_numericality_of :unit_code, greater_than_or_equal_to: 0
  validates_numericality_of :site_code, greater_than_or_equal_to: 0

  # Todo: validate all Clinics with same Unit Code must have same Unit Name

  PERMITTED_STATES = %w(ACT NSW NT QLD SA TAS VIC WA NZ)
  validates_inclusion_of :state, in: PERMITTED_STATES, message: "must be one of #{PERMITTED_STATES.to_s}"

  GROUP_BY_STATE_WITH_CLINIC = 0
  GROUP_BY_STATE_WITH_UNIT = 1

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

  def self.clinics_with_unit_code(unit_code)
    where(unit_code: unit_code)
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
