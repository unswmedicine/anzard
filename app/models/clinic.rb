class Clinic < ApplicationRecord

  has_many :clinic_allocations
  has_many :users, through: :clinic_allocations
  has_many :responses

  validates_presence_of :state
  validates_presence_of :unit_name
  validates_presence_of :unit_code
  validates_presence_of :site_name
  validates_presence_of :site_code

  validates_uniqueness_of :site_code, scope: :unit_code

  WITHOUT_SITE_NAME = "without_site_name"
  WITH_SITE_NAME = "with_site_name"
  WITH_UNIT = "with_unit"

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

  def self.clinics_by_state
    clinics_by_state_with_unit_or_with_or_without_site_name(WITHOUT_SITE_NAME)
  end

  def self.clinics_by_state_with_site_name
    clinics_by_state_with_unit_or_with_or_without_site_name(WITH_SITE_NAME)
  end

  def self.clinics_by_state_and_unique_by_unit
    clinics_by_state_with_unit_or_with_or_without_site_name(WITH_UNIT)
  end

  private

  def self.clinics_by_state_with_unit_or_with_or_without_site_name(with_site_name_or_unit)
    clinics = order(:unit_name).all
    grouped = clinics.group_by(&:state)

    output = case with_site_name_or_unit
               when WITHOUT_SITE_NAME
                 grouped.collect { |state, clinics| [state, clinics.collect { |h| [h.unit_name, h.id] }] }
               when WITH_SITE_NAME
                 grouped.collect { |state, clinics| [state, clinics.collect { |h| [h.site_name.blank? ?  h.unit_name : h.unit_name + ' - ' + h.site_name, h.id] }] }
               when WITH_UNIT
                 # Todo: figure out why this is using unit_code as the value rather than the clinic id
                 grouped.collect { |state, clinics| [state, clinics.collect { |h| [h.unit_name + ' (' + h.unit_code.to_s + ')', h.unit_code] }] }
             end

    output.each do |key, value|
      value.uniq!
    end
    output.sort { |a, b| a[0] <=> b[0] }
  end

end
