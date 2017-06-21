Given /^I have clinics$/ do |table|
  table.hashes.each do |hash|
    Factory(:clinic, hash)
  end
end
