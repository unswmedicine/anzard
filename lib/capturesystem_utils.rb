module CapturesystemUtils

  def self.master_site_base_url
    Rails.cache.fetch("master_site_base_url", compress:false) do
      Rails.logger.debug('Fetching [master_site_base_url]')
      ConfigurationItem.find_by(name:'master_site_base_url').configuration_value
    end
  end

  def self.master_site_name
    Rails.cache.fetch("master_site_name", compress:false) do
      Rails.logger.debug('Fetching [master_site_name]')
      ConfigurationItem.find_by(name:'master_site_name').configuration_value
    end
  end
end