def create_capturesystems
  Capturesystem.delete_all

  Capturesystem.create(name: 'ANZARD', base_url: 'https://anzard.med.unsw.edu.au')
end


def create_roles_and_permissions
  Role.delete_all

  Role.create!(:name => Role::SUPER_USER)
  Role.create!(:name => Role::DATA_PROVIDER)
  Role.create!(:name => Role::DATA_PROVIDER_SUPERVISOR)

end

def create_config_items
  ConfigurationItem.delete_all

  ConfigurationItem.create!(name: 'master_site_base_url', configuration_value: 'https://npesu.med.unsw.edu.au')
  ConfigurationItem.create!(name: 'master_site_name', configuration_value: 'NPESU')

  #ANZARD year range (interpreated as calendar year)
  ConfigurationItem.create!(name: ConfigurationItem::YEAR_OF_REGISTRATION_START, configuration_value: "2005")
  ConfigurationItem.create!(name: ConfigurationItem::YEAR_OF_REGISTRATION_END, configuration_value: "2012")
end

def create_clinics
  Clinic.delete_all

  clinics = read_hashes_from_csv(Rails.root.join("db/seed_files", "clinics.csv"))
  clinics.each do |hash|
    clinic = Clinic.new(capturesystem: Capturesystem.find(1),
                        state:hash['State'].strip,
                        unit_name: hash['Unit_Name'].strip,
                        unit_code: hash['Unit_Code'].strip,
                        site_name: hash['Site_Name'].strip,
                        site_code: hash['Site_Code'].strip)
    clinic.save!
  end
end