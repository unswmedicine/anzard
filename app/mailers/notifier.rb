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

class Notifier < ActionMailer::Base

  def notify_user_of_approved_request(recipient, capturesystem)
    @user = recipient
    @capturesystem = capturesystem

    mail( to: @user.email,
          from: APP_CONFIG['account_request_user_status_email_sender'],
          reply_to: APP_CONFIG['account_request_user_status_email_sender'],
          subject: "#{@capturesystem.name} -Your access request has been approved")
  end

  def notify_user_of_rejected_request(recipient, capturesystem)
    @user = recipient
    @capturesystem = capturesystem

    mail( to: @user.email,
          from: APP_CONFIG['account_request_user_status_email_sender'],
          reply_to: APP_CONFIG['account_request_user_status_email_sender'],
          subject: "#{@capturesystem.name} - Your access request has been rejected")
  end

  # notifications for super users
  def notify_superusers_of_access_request(applicant, capturesystem)
    superusers_emails = applicant.capturesystems.map {|r| r.users.get_superuser_emails }.flatten.uniq
    @user = applicant
    @capturesystem = capturesystem

    mail( to: superusers_emails,
          from: APP_CONFIG['account_request_admin_notification_sender'],
          reply_to: @user.email,
          subject: "#{@capturesystem.name} - There has been a new access request")
  end

  def notify_user_that_they_cant_reset_their_password(user, capturesystem)
    @user = user
    @capturesystem = capturesystem

    mail( to: @user.email,
          from: APP_CONFIG['password_reset_email_sender'],
          reply_to: APP_CONFIG['password_reset_email_sender'],
          subject: "#{@capturesystem.name} - Reset password instructions")
  end

  private

  def mail(headers, &block)
    self.default_url_options[:host] = @capturesystem.base_url
    super
  end

end
