class Capturesystem < ApplicationRecord
  has_many :capturesystem_users
  has_many :users, through: :capturesystem_users

  has_many :capturesystem_surveys
  has_many :surveys, through: :capturesystem_surveys

  has_many :clinics

  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :base_url, presence: true, uniqueness: {case_sensitive: false}

  def long_name
    ConfigurationItem.find_by(name:"#{self.name}_LONG_NAME")&.configuration_value || self.name
  end

  def host
    uri = URI.parse(self.base_url)
  end

  def host_with_port
    uri = URI.parse(self.base_url)
    uri.host + ':' + uri.port
  end

end
