class Clinic < ApplicationRecord

  has_many :users
  has_many :responses

  validates_presence_of :name
  validates_presence_of :state
  validates_presence_of :unit
  validates_presence_of :site

  WITHOUT_SITE_NAME = "without_site_name"
  WITH_SITE_NAME = "with_site_name"
  WITH_UNIT = "with_unit"

  def self.hospitals_by_state
    hospitals_by_state_with_unit_or_with_or_without_site_name(WITHOUT_SITE_NAME)
  end

  def self.hospitals_by_state_with_site_name
    hospitals_by_state_with_unit_or_with_or_without_site_name(WITH_SITE_NAME)
  end

  def self.hospitals_by_state_and_unique_by_unit
    hospitals_by_state_with_unit_or_with_or_without_site_name(WITH_UNIT)
  end

  private

  def self.hospitals_by_state_with_unit_or_with_or_without_site_name(with_site_name_or_unit)
    hospitals = order(:name).all
    grouped = hospitals.group_by(&:state)

    output = case with_site_name_or_unit
               when WITHOUT_SITE_NAME
                 grouped.collect { |state, hospitals| [state, hospitals.collect { |h| [h.name, h.id] }] }
               when WITH_SITE_NAME
                 grouped.collect { |state, hospitals| [state, hospitals.collect { |h| [h.site_name.blank? ?  h.name : h.name + ' - ' + h.site_name, h.id] }] }
               when WITH_UNIT
                 grouped.collect { |state, hospitals| [state, hospitals.collect { |h| [h.name + ' (' + h.unit.to_s + ')', h.unit] }] }
             end

    output.each do |key, value|
      value.uniq!
    end
    output.sort { |a, b| a[0] <=> b[0] }
  end

end
