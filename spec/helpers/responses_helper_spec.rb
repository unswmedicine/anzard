require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the ResponsesHelper. For example:
#
# describe ResponsesHelper, :type => :helper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       helper.concat_strings("this","that").should == "this that"
#     end
#   end
# end

describe ResponsesHelper, :type => :helper do
  describe "Generating response page titles" do
    it "should string together survey, cycle id and year of reg" do
      response = create(:response, baby_code: "Bcdef", year_of_registration: 2015, survey: create(:survey, name: "My Survey"))
      helper.response_title(response).should eq("My Survey - Cycle ID Bcdef - Year of Treatment 2015")
    end
  end
end
