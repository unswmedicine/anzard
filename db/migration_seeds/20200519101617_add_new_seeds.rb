class SchemaMigration < ActiveRecord::Base
  self.primary_key = :version
end

def do_ar_records(model, method_name, params_list)
  if model.is_a?(Symbol)
    ar = ActiveRecord.const_get(model)
  else
    ar = model
  end

  #['find_or_create_by', 'update', 'where'].include?(method_name.to_s)
  if ar.respond_to?(method_name)
    m = ar.method(method_name)
    if params_list.respond_to?(:each)
      if params_list.respond_to?(:each_pair)
        puts("#{ar}.#{method_name}(#{params_list})")
        return m.call(params_list)
      else
        return params_list.map do |p|
          puts("#{ar}.#{method_name}(#{p})")
          m.call(p)
        end
      end
    else
      puts("#{params_lsit} is not iterable")
      return nil
    end
  else
    puts("Expanding #{ar}.#{method_name} =>")
    params_list.each_pair do |k, v|
      ar = do_ar_records(ar, k, v)
    end
    return ar
  end

end

def migrate_seeds(seeds_data)
#ruby version has to be > 1.9 to be in order
  seeds_data.each do |model_name, changes|
    changes.each do |method_name, params_list|
      do_ar_records(model_name, method_name, params_list)
    end
  end
end


###################
def main_main(version_list)
  unless SchemaMigration.where(version: version_list ).count == version_list.count
    puts 'You have missing migrations to run this script'
  else

    ########################
    seeds_data = {}

    varta_admin_emails = []
    if Rails.env.development?
      seeds_data = {
        Capturesystem: {
          find_or_create_by: [
            { name: 'ANZARD', base_url: 'http://anzard.med.unsw.edu.au:3000' },
            { name: 'VARTA', base_url: 'http://varta.med.unsw.edu.au:3000' }
          ]
        },
        ConfigurationItem: {
          find_or_create_by: [
            { name: 'master_site_name', configuration_value: 'NPESU' },
            { name: 'master_site_base_url', configuration_value: 'http://npesu.med.unsw.edu.au:3000' },
            { name: 'ANZARD_LONG_NAME', configuration_value: 'Australian & New Zealand Assisted Reproduction Database' },
            { name: 'VARTA_LONG_NAME', configuration_value: 'Victoria Assisted Reproduction Treatment Authority' }
         ]
        }
      }
      varta_admin_emails = [
        'admin@intersect.org.au'
      ]
    elsif Rails.env.qa?
      seeds_data = {
        Capturesystem: {
          find_or_create_by: [
            { name: 'ANZARD', base_url: 'https://anzard-npesu-qa.intersect.org.au' },
            { name: 'VARTA', base_url: 'https://varta-npesu-qa.intersect.org.au' }
          ]
        },
        ConfigurationItem: {
          find_or_create_by: [
            { name: 'master_site_name', configuration_value: 'NPESU' },
            { name: 'master_site_base_url', configuration_value: 'https://npesu-qa.intersect.org.au' },
            { name: 'ANZARD_LONG_NAME', configuration_value: 'Australian & New Zealand Assisted Reproduction Database' },
            { name: 'VARTA_LONG_NAME', configuration_value: 'Victoria Assisted Reproduction Treatment Authority' }
         ]
        } 
      }
      varta_admin_emails = [
        'admin@intersect.org.au'
      ]
    elsif Rails.env.staging?
      seeds_data = {
        Capturesystem: {
          find_or_create_by: [
            { name: 'ANZARD', base_url: 'https://anzard-npesu-staging.intersect.org.au' },
            { name: 'VARTA', base_url: 'https://varta-npesu-staging.intersect.org.au' }
          ]
        },
        ConfigurationItem: {
          find_or_create_by: [
            { name: 'master_site_name', configuration_value: 'NPESU' },
            { name: 'master_site_base_url', configuration_value: 'https://npesu-staging.intersect.org.au' },
            { name: 'ANZARD_LONG_NAME', configuration_value: 'Australian & New Zealand Assisted Reproduction Database' },
            { name: 'VARTA_LONG_NAME', configuration_value: 'Victoria Assisted Reproduction Treatment Authority' }
         ]
        } 
      }
      varta_admin_emails = [
        'admin@intersect.org.au'
      ]
    else
    #default production
      seeds_data = {
        Capturesystem: {
          find_or_create_by: [
            { name: 'ANZARD', base_url: 'https://anzard.med.unsw.edu.au' },
            { name: 'VARTA', base_url: 'https://varta.med.unsw.edu.au' }
          ]
        },
        ConfigurationItem: {
          find_or_create_by: [
            { name: 'master_site_name', configuration_value: 'NPESU' },
            { name: 'master_site_base_url', configuration_value: 'https://npesu.med.unsw.edu.au' },
            { name: 'ANZARD_LONG_NAME', configuration_value: 'Australian & New Zealand Assisted Reproduction Database' },
            { name: 'VARTA_LONG_NAME', configuration_value: 'Victoria Assisted Reproduction Treatment Authority' }
         ]
        } 
      } 
      #TODO udpate this
      varta_admin_emails = [
      ]
    end
    migrate_seeds(seeds_data)

    ########################
    anzard_cs_id = Capturesystem.find_by(name:'ANZARD').id
    varta_cs_id = Capturesystem.find_by(name:'VARTA').id
    seeds_data = {
      Clinic: {
        populate_capturesystem_id: {
          where: {capturesystem_id:[nil, '']},
          update: [{capturesystem_id: anzard_cs_id}]
        },
        find_or_create_by: Clinic.where(state:'VIC').map { |c|
          {
            state:c.state, 
            unit_name:c.unit_name, 
            unit_code:c.unit_code, 
            site_code:c.site_code, 
            site_name:c.site_name, 
            active:true, 
            capturesystem_id:varta_cs_id 
          }
        }
      },
      CapturesystemSurvey: {
        find_or_create_by: Survey.order(:id).map { |survey|
          { survey_id: survey.id, capturesystem_id: anzard_cs_id }
        }
      },
      CapturesystemUser: {
        find_or_create_by: (
          User.order(:id).map { |user|
            { user_id: user.id, capturesystem_id: anzard_cs_id, access_status: CapturesystemUser::STATUS_ACTIVE }
          } +
          User.where(email: varta_admin_emails).map { |user|
            { user_id: user.id, capturesystem_id: varta_cs_id, access_status: CapturesystemUser::STATUS_ACTIVE }
          }
        )
      }
    }
    migrate_seeds(seeds_data)

    seeds_data = {
      ConfigurationItem: {
        update_ANZARD_YearOfRegStart_name: {
          where: {name: 'YearOfRegStart'},
          update: [{name: 'ANZARD_YearOfRegStart'}]
        },
        update_ANZARD_YearOfRegEnd_name: {
          where: {name: 'YearOfRegEnd'},
          update: [{name: 'ANZARD_YearOfRegEnd'}]
        },
        find_or_create_by: [
          {name: 'VARTA_YearOfRegStart', configuration_value:'2015'},
          {name: 'VARTA_YearOfRegEnd', configuration_value:'2025'}
        ]
      }
    }
    migrate_seeds(seeds_data)

  end
end

###################
if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('1.9')
  main_main([
'20200419131736',
'20200420095747',
'20200424034147',
'20200424043742',
'20200428011938',
'20200428020513',
'20200507075811',
'20200507080709'
])
else
  puts 'Aborted, your ruby version is too older: <= 1.9 !!'
end

