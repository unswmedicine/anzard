def create_roles_and_permissions
  Role.delete_all

  Role.create!(:name => Role::SUPER_USER)
  Role.create!(:name => Role::DATA_PROVIDER)
  Role.create!(:name => Role::DATA_PROVIDER_SUPERVISOR)

end

def create_config_items
  ConfigurationItem.create!(name: ConfigurationItem::YEAR_OF_REGISTRATION_START, configuration_value: "2005")
  ConfigurationItem.create!(name: ConfigurationItem::YEAR_OF_REGISTRATION_END, configuration_value: "2012")
end

def create_clinics
  Clinic.delete_all

  clinics = read_hashes_from_csv(Rails.root.join("db/seed_files", "clinics.csv"))
  clinics.each do |hash|
    clinic = Clinic.new(state:hash['State'].strip,
                            name: hash['Unit_Name'].strip,
                            unit: hash['Unit_Code'].strip,
                            site_name: hash['Site_Name'].strip,
                            site: hash['Site_Code'].strip)
    clinic.save!
  end
end