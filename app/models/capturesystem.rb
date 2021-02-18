class Capturesystem < ApplicationRecord
  has_many :capturesystem_users
  has_many :users, through: :capturesystem_users

  has_many :capturesystem_surveys
  has_many :surveys, through: :capturesystem_surveys

  has_many :clinics

  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :base_url, presence: true, uniqueness: {case_sensitive: false}

  def long_name
    Rails.cache.fetch("capturesystem#long_name/#{self.name}", compress:false) do
      logger.debug("Fetching [capturesystem#long_name/#{self.name}]")
      ConfigurationItem.find_by(name:"#{self.name}_LONG_NAME")&.configuration_value || self.name
    end
  end

  def host
    uri = URI.parse(self.base_url)
  end

  def host_with_port
    uri = URI.parse(self.base_url)
    uri.host + ':' + uri.port
  end

  def active_superusers_emails
    self.users.approved_superusers.where(capturesystem_users: {access_status: CapturesystemUser::STATUS_ACTIVE}).pluck(:email).uniq
  end

end
