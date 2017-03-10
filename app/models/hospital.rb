class Hospital < ApplicationRecord

  has_many :users
  has_many :responses

  validates_presence_of :name
  validates_presence_of :state
  validates_presence_of :unit
  validates_presence_of :site

  def self.hospitals_by_state
    hospitals_by_state_with_or_without_site_name(false)
  end

  def self.hospitals_by_state_with_site_name
    hospitals_by_state_with_or_without_site_name(true)
  end

  private

  def self.hospitals_by_state_with_or_without_site_name(with_site_name)
    hospitals = order(:name).all
    grouped = hospitals.group_by(&:state)
    if with_site_name
      output = grouped.collect { |state, hospitals| [state, hospitals.collect { |h| [h.site_name.blank? ?  h.name : h.name + ' - ' + h.site_name, h.id] }] }
    else
      output = grouped.collect { |state, hospitals| [state, hospitals.collect { |h| [h.name, h.id] }] }
    end
    output.sort { |a, b| a[0] <=> b[0] }
  end

end
