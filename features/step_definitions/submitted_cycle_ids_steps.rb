When /^clinic "([^"]*)" has submitted the following cycle ids$/ do |clinic, table|
  # table is a | 2012 | abcd      | main |pending
  clinic = Clinic.find_by_unit_name!(clinic)
  roles = Role.where(name: [Role::DATA_PROVIDER, Role::DATA_PROVIDER_SUPERVISOR])
  user = clinic.users.where(role_id: roles).first!
  table.hashes.each do |hash|
    survey = hash[:form]
    Factory.create(:response, user: user, clinic: user.clinic,
                   submitted_status: Response::STATUS_SUBMITTED, cycle_id: hash[:cycle_id],
                   year_of_registration: hash[:year], survey: Survey.find_by_name!(survey))
  end
end
When /^I should see the following cycle ids$/ do |table|
  # table is a | followup | 2011 | cycle2     |pending
  # parse the html into an array of arrays
  form_divs = all('div.form')
  actual_cycle_ids = form_divs.map do |form_div|
    form_header = form_div.find('h1.form')
    year_divs = form_div.all('div.year')

    year_contents = year_divs.map do |year_div|
      year_header = year_div.find('h2.year')
      cycle_ids = year_div.all('li').map {|li| li.text }
      [year_header.text, cycle_ids]
    end

    [form_header.text, year_contents]
  end

  expected_codes = {}

  hashes_by_form = table.hashes.group_by{|hash| hash[:form]}
  hashes_by_form.each do |form_name, hashes|
    hashes_by_year = hashes.group_by {|hash| hash[:year]}

    expected_codes[form_name] = {}
    hashes_by_year.each do |year, hashes|
      expected_codes[form_name][year] = hashes.map{|hash| hash[:cycle_id]}.sort
    end
  end

  expected_codes = expected_codes.map do |form_name, expected_year_data|
    [form_name, expected_year_data.map{|year, expected_cycle_ids| [year, expected_cycle_ids] } ]
  end

  actual_cycle_ids.should eq expected_codes
end