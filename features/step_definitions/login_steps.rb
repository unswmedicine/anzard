Given /^I have a user "([^"]*)"$/ do |email|
  Factory(:user, :email => email, :password => "Pas$w0rd", :status => 'A')
end

Given /^I have a locked user "([^"]*)"$/ do |email|
  Factory(:user, :email => email, :password => "Pas$w0rd", :status => 'A', :locked_at => Time.now - 30.minute, :failed_attempts => 3)
end

Given /^I have a deactivated user "([^"]*)"$/ do |email|
  Factory(:user, :email => email, :password => "Pas$w0rd", :status => 'D')
end

Given /^I have a rejected as spam user "([^"]*)"$/ do |email|
  Factory(:user, :email => email, :password => "Pas$w0rd", :status => 'R')
end

Given /^I have a pending approval user "([^"]*)"$/ do |email|
  Factory(:user, :email => email, :password => "Pas$w0rd", :status => 'U')
end

Given /^I have a user "([^"]*)" with an expired lock$/ do |email|
  Factory(:user, :email => email, :password => "Pas$w0rd", :status => 'A', :locked_at => Time.now - 1.hour - 1.second, :failed_attempts => 3)
end

Given /^I have a user "([^"]*)" with role "([^"]*)"$/ do |email, role|
  create_user_with_role(email, role)
end

Given /^I have a user "([^"]*)" with role "([^"]*)" and clinic "([^"]*)"$/ do |email, role, clinic|
  create_usual_roles
  user = create_user_with_role(email, role)
  link_user_to_clinic(user, clinic)
end

Given /^"([^"]*)" has name "([^"]*)" "([^"]*)"$/ do |email, first, last|
  u = User.find_by_email!(email)
  u.first_name = first
  u.last_name = last
  u.save!
end

Given /^I am logged in as "([^"]*)" and have role "([^"]*)" and I'm linked to clinic "([^"]*)"$/ do |email, role, clinic_name|
  create_usual_roles
  user = create_user_with_role(email, role) unless User.find_by_email(email)
  link_user_to_clinic(user, clinic_name)
  log_in(email)
end

Given /^I am logged in as "([^"]*)" and have role "([^"]*)"$/ do |email, role|
  create_usual_roles
  create_user_with_role(email, role) unless User.find_by_email(email)
  log_in(email)
end

Given /^I am logged in as "([^"]*)"$/ do |email|
  log_in(email)
end

Given /^I have no users$/ do
  User.delete_all
end

Then /^I should be able to log in with "([^"]*)" and "([^"]*)"$/ do |email, password|
  visit path_to("the logout page")
  visit path_to("the login page")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button("Log in")
  page.should have_content('Logged in successfully.')
  current_path.should == path_to('the home page')
end

When /^I attempt to login with "([^"]*)" and "([^"]*)"$/ do |email, password|
  visit path_to("the login page")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => password)
  click_button("Log in")
end

Then /^the failed attempt count for "([^"]*)" should be "([^"]*)"$/ do |email, count|
  user = User.where(:email => email).first
  user.failed_attempts.should == count.to_i
end

And /^I request a reset for "([^"]*)"$/ do |email|
  visit path_to("the home page")
  click_link "Forgot your password?"
  fill_in "Email", :with => email
  click_button "Send me reset password instructions"
end

Given /^I have the usual roles$/ do
  create_usual_roles
end

Given /^"([^"]*)" has clinic "([^"]*)"$/ do |email, clinic|
  link_user_to_clinic(User.find_by_email!(email), clinic)
end


def create_usual_roles
  Role.create!(:name => Role::SUPER_USER) unless Role.find_by_name(Role::SUPER_USER)
  Role.create!(:name => Role::DATA_PROVIDER) unless Role.find_by_name(Role::DATA_PROVIDER)
  Role.create!(:name => Role::DATA_PROVIDER_SUPERVISOR) unless Role.find_by_name(Role::DATA_PROVIDER_SUPERVISOR)
end

def create_user_with_role(email, role_name)
  clinic = role_name == Role::SUPER_USER ? nil : Factory(:clinic)
  user = Factory(:user, :email => email, :password => "Pas$w0rd", :status => 'A', clinic: clinic)
  role = Role.find_by_name!(role_name)
  user.role_id = role.id
  user.save!
  user
end

def log_in(email)
  visit path_to("the logout page")
  visit path_to("the login page")
  fill_in("user_email", :with => email)
  fill_in("user_password", :with => "Pas$w0rd")
  click_button("Log in")
end

def link_user_to_clinic(user, clinic_name)
  clinic = Clinic.find_by_unit_name(clinic_name)
  clinic ||= Factory(:clinic, name: clinic_name)
  user.clinic = clinic
  user.save!
end