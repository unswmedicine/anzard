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
  Hospital.delete_all

  clinics = read_hashes_from_csv(Rails.root.join("db/seed_files", "clinics.csv"))
  clinics.each do |hash|
    #Hospital.create!(hash)

    hospital = Hospital.new(name: hash['name'].strip,
                            state:hash['state'].strip,
                            unit: hash['unit'].strip,
                            site: hash['site'].strip,
                            site_name: hash['site_name'].strip)
    hospital.save!
  end
end