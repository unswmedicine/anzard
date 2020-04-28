# ANZARD - Australian & New Zealand Assisted Reproduction Database
# Copyright (C) 2017 Intersect Australia Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

require 'csv'
require 'csv_survey_operations.rb'

include CsvSurveyOperations

SURVEY_NAME = 'ANZARD 2.0'
ALL_MANDATORY = 1
ALL = 2
FEW = 3

def populate_data(big=false)
  puts "Creating sample data in #{Rails.env} environment..."

  puts "Deleting all CapturesystemUser,User records !!!"
  CapturesystemUser.delete_all
  User.delete_all

  load_password
  puts "Creating test users..."
  create_test_users
  puts 'Upadate and add capture system'
  update_and_add_new_capturesystem
  puts 'Add config items for capturesystems'
  add_config_items
  puts "Creating capturesystem_users..."
  create_capturesystem_users

  puts "Creating surveys..."
  create_surveys
  puts "Creating capturesystem_surveys..."
  create_capturesystem_surveys

  if %w(development qa).include? Rails.env
    puts "Creating responses..."
    create_responses(big)
  end

  puts "Ended creating sample data in #{Rails.env} environment..."
end

def create_responses(big)
  Response.delete_all
  main = Survey.where(:name => SURVEY_NAME).first

  # remove the one dataprovider is linked to as we'll create those separately
  dp_clinics = User.find_by_email!('dataprovider@anzard.intersect.org.au').clinics
  clinics = Clinic.where.not(id: dp_clinics.pluck(:id))

  count1 = big ? 100 : 20
  count2 = big ? 30 : 5
  count3 = big ? 500 : 50

  count1.times { create_response(main, ALL_MANDATORY, clinics.sample) }
  count2.times { create_response(main, ALL, clinics.sample) }
  #count2.times { create_response(main, FEW, clinics.sample) }

  create_response(main, ALL_MANDATORY, dp_clinics.first)
  create_response(main, ALL, dp_clinics.first)
  #create_response(main, FEW, dp_clinic)

  create_batch_files(main)

  # create some submitted ones (this is a bit dodgy since they aren't valid, but its too hard to create valid ones in code)
  count3.times { create_response(main, ALL_MANDATORY, clinics.sample, true) }
  count3.times { create_response(main, ALL, clinics.sample, true) }

end

def update_and_add_new_capturesystem
  Capturesystem.where(name: 'ANZARD').update(base_url:'http://anzard.med.unsw.edu.au:3000')
  Capturesystem.create(name: 'VARTA', base_url: 'http://varta.med.unsw.edu.au:3000')
end

def add_config_items
  ConfigurationItem.create!(name: "ANZARD_LONG_NAME", configuration_value: "Australian & New Zealand Assisted Reproduction Database")
  ConfigurationItem.create!(name: "VARTA_LONG_NAME", configuration_value: "Victoria Assisted Reproduction Treatment Authority")
end


def create_surveys
  Response.delete_all
  BatchFile.delete_all
  Survey.delete_all
  Section.delete_all
  Question.delete_all
  QuestionOption.delete_all
  CrossQuestionValidation.delete_all

  create_survey_from_lib_tasks(SURVEY_NAME, 'main_questions.csv', 'main_question_options.csv', 'main_cross_question_validations.csv', 'test_data/survey/real_survey')
  create_survey_from_lib_tasks('VARTA 1.0', 'main_questions.csv', 'main_question_options.csv', 'main_cross_question_validations.csv', 'test_data/survey/real_survey')
end

def create_capturesystem_surveys
  CapturesystemSurvey.create(survey_id: Survey.find_by(name:'ANZARD 2.0').id, capturesystem_id: Capturesystem.find_by(name:'ANZARD').id)
  CapturesystemSurvey.create(survey_id: Survey.find_by(name:'VARTA 1.0').id, capturesystem_id: Capturesystem.find_by(name:'VARTA').id)
end

def create_survey_from_lib_tasks(name, question_file, options_file, cross_question_validations_file, dir='lib/tasks')
  path_to = ->(filename) { Rails.root.join dir, filename }
  create_survey(name, path_to[question_file], path_to[options_file], path_to[cross_question_validations_file])
end

def create_test_users
  create_user(email: 'kali@intersect.org.au', first_name: 'Kali', last_name: 'Waterford')
  set_role('kali@intersect.org.au', 'Administrator')

  create_user(email: 'admin@anzard.intersect.org.au', first_name: 'Administrator', last_name: 'Anzard')
  set_role('admin@anzard.intersect.org.au', 'Administrator')

  create_user(email: 'dataprovider@anzard.intersect.org.au', first_name: 'Data', last_name: 'Provider')
  set_role('dataprovider@anzard.intersect.org.au', 'Data Provider', Clinic.first.id)

  create_user(email: 'supervisor@anzard.intersect.org.au', first_name: 'Data', last_name: 'Supervisor')
  set_role('supervisor@anzard.intersect.org.au', 'Data Provider Supervisor', Clinic.first.id)

  create_user(email: 'dataprovider2@anzard.intersect.org.au', first_name: 'Data', last_name: 'Provider2')
  set_role('dataprovider2@anzard.intersect.org.au', 'Data Provider', Clinic.last.id)
  
  create_user(email: 'supervisor2@anzard.intersect.org.au', first_name: 'Data', last_name: 'Supervisor2')
  set_role('supervisor2@anzard.intersect.org.au', 'Data Provider Supervisor', Clinic.last.id)

  create_unapproved_user(email: 'unapproved1@anzard.intersect.org.au', first_name: 'Unapproved', last_name: 'One')
  create_unapproved_user(email: 'unapproved2@anzard.intersect.org.au', first_name: 'Unapproved', last_name: 'Two')
end

def create_capturesystem_users
  User.order(:id).each do |r|
    CapturesystemUser.create(user_id: r.id, capturesystem_id: Capturesystem.find_by(name:'ANZARD').id)
  end

  CapturesystemUser.create(user_id: User.find_by(email:'admin@anzard.intersect.org.au').id, capturesystem_id: Capturesystem.find_by(name:'VARTA').id)
end

def set_role(email, role, clinic_id=nil)
  user = User.find_by_email(email)
  role = Role.find_by_name(role)
  user.role = role
  unless clinic_id.nil?
    clinic = Clinic.find(clinic_id)
    user.clinics = [clinic]
    user.allocated_unit_code = clinic.unit_code
  end
  user.save!
end

def create_user(attrs)
  u = User.new(attrs.merge(password: @password))
  u.activate
  u.save!
end

def create_unapproved_user(attrs)
  u = User.create!(attrs.merge(password: @password))
  u.save!
end

def load_password
  password_file = "#{Rails.root}/tmp/env_config/sample_password.yml"
  if File.exists? password_file
    puts "Using sample user password from #{password_file}"
    password = YAML::load_file(password_file)
    @password = password[:password]
    return
  end

  if Rails.env.development?
    puts "#{password_file} missing.\n" +
             "Set sample user password:"
    input = STDIN.gets.chomp
    buffer = Hash[password: input]
    Dir.mkdir("#{Rails.root}/tmp", 0755) unless Dir.exists?("#{Rails.root}/tmp")
    Dir.mkdir("#{Rails.root}/tmp/env_config", 0755) unless Dir.exists?("#{Rails.root}/tmp/env_config")
    File.open(password_file, 'w') do |out|
      YAML::dump(buffer, out)
    end
    @password = input
  else
    raise "No sample password file provided, and it is required for any environment that isn't development\n" +
              "Use capistrano's deploy:populate task to generate one"
  end

end

def create_response(survey, profile, clinic, submit=false)
  status = Response::STATUS_UNSUBMITTED
  year_of_reg = 2007
  base_date = random_date_in(2007)
  prefix = case profile
             when ALL
               "big"
             when ALL_MANDATORY
               "med"
             when FEW
               "small"
           end
  response = Response.create!(clinic: clinic,
                              submitted_status: status,
                              cycle_id: "#{prefix}-#{clinic.unit_site_code}-#{rand(10000)}",
                              survey: survey,
                              year_of_registration: year_of_reg,
                              user: User.all.sample)


  questions = case profile
                when ALL
                  survey.questions
                when ALL_MANDATORY
                  survey.questions.where(:mandatory => true)
                when FEW
                  survey.questions.all[1..15]
              end
  questions.each do |question|
    answer = response.answers.build(question_id: question.id)
    answer_value = case question.question_type
                     when Question::TYPE_CHOICE
                       random_choice(question)
                     when Question::TYPE_DATE
                       random_date(base_date)
                     when Question::TYPE_DECIMAL
                       random_number(question)
                     when Question::TYPE_INTEGER
                       random_number(question)
                     when Question::TYPE_TEXT
                       random_text(question)
                     when Question::TYPE_TIME
                       random_time
                   end
    answer.answer_value = answer_value
    answer.save!
  end
  if submit
    response.submitted_status = Response::STATUS_SUBMITTED
    response.save!
  end
end

def create_batch_files(survey)
  create_batch_file(survey, 5)
  create_batch_file(survey, 50)
  create_batch_file(survey, 500)
end

def create_batch_file(survey, count_of_rows)
  # this is a useful way to create sample batch files for testing the upload feature
  responses = Response.where(survey_id: survey.id).all
  responses_to_use = responses.sample(count_of_rows)

  csv = CsvGenerator.new(survey.id, nil, nil,nil)
  csv.records = responses_to_use

  filepath = "#{Rails.root}/tmp/batch-#{survey.name.parameterize}-#{count_of_rows}.csv"
  File.open(filepath, 'w') do |out|
    out.puts csv.csv
  end

end

def random_date_in(year)
  days = rand(364)
  Date.new(year, 1, 1) + days.days
end

def random_choice(question)
  question.question_options.all.sample.option_value
end

def random_date(base_date)
  base_date + rand(-30..30).days
end

def random_number(question)
  end_of_range = question.number_max ? question.number_max : 500
  start_of_range = question.number_min ? question.number_min : -500
  rand(start_of_range..end_of_range)
end

def random_text(question)
  rand(-999999..999999).to_s
end

def random_time
  "#{rand(0..23)}:#{rand(0..59)}"
end


