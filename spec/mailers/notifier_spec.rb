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

#require "spec_helper"
require 'rails_helper'

describe Notifier do
  let(:capturesystem) { create(:capturesystem, name:'ANZARD', base_url:'http://localhost:3000') }
  
  describe "Email notifications to users should be sent" do
    it "should send mail to user if access request approved" do
      address = 'user@email.org'
      user = create(:user, :status => "A", :email => address)
      email = Notifier.notify_user_of_approved_request(user, 'NPESU', 'localhost', capturesystem).deliver
  
      # check that the email has been queued for sending
      ActionMailer::Base.deliveries.empty?.should eq(false) 
      email.to.should eq([address])
      email.subject.should eq("NPESU | ANZARD - Your access request has been approved")
    end

    it "should send mail to user if access request denied" do
      address = 'user@email.org'
      user = create(:user, :status => "A", :email => address)
      email = Notifier.notify_user_of_rejected_request(user, 'NPESU', capturesystem).deliver
  
      # check that the email has been queued for sending
      ActionMailer::Base.deliveries.empty?.should eq(false) 
      email.to.should eq([address])
      email.subject.should eq("NPESU | ANZARD - Your access request has been rejected")
    end
  end

  describe "Notification to superusers when new access request created"
  it "should send the right email" do
    address = 'user@email.org'
    user = create(:user, :status => "U", :email => address)
    User.should_receive(:get_superuser_emails) { ["super1@intersect.org.au", "super2@intersect.org.au"] }
    email = Notifier.notify_superusers_of_access_request(user, 'NPESU', capturesystem.base_url, capturesystem).deliver

    # check that the email has been queued for sending
    ActionMailer::Base.deliveries.empty?.should eq(false)
    email.subject.should eq("NPESU | ANZARD - There has been a new access request")
    email.to.should eq(["super1@intersect.org.au", "super2@intersect.org.au"])
  end
 
end
