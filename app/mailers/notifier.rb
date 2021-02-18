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

  def notify_user_of_approved_request(recipient, system_name, system_base_url, capturesystem)
    @user = recipient
    @capturesystem = capturesystem
    @host_url = system_base_url

    mail( to: @user.email,
          from: APP_CONFIG['account_request_user_status_email_sender'],
          reply_to: APP_CONFIG['account_request_user_status_email_sender'],
          subject: "#{system_name} | #{@capturesystem.name} - Your access request has been approved")
  end

  def notify_user_of_rejected_request(recipient, system_name, capturesystem)
    @user = recipient
    @capturesystem = capturesystem

    mail( to: @user.email,
          from: APP_CONFIG['account_request_user_status_email_sender'],
          reply_to: APP_CONFIG['account_request_user_status_email_sender'],
          subject: "#{system_name} | #{@capturesystem.name} - Your access request has been rejected")
  end

  # notifications for super users
  def notify_superusers_of_access_request(applicant, system_name, system_base_url, capturesystem)
    #superusers_emails = capturesystem.users.get_superuser_emails.flatten.uniq
    active_superusers_emails = capturesystem.active_superusers_emails
    @user = applicant
    @host_url = system_base_url
    mail( to: active_superusers_emails,
          from: APP_CONFIG['account_request_admin_notification_sender'],
          reply_to: @user.email,
          subject: "#{system_name} | #{capturesystem.name} - There has been a new access request")
  end

  def notify_user_that_they_cant_reset_their_password(user, system_name)
    @user = user
    @system_name = system_name

    mail( to: @user.email,
          from: APP_CONFIG['password_reset_email_sender'],
          reply_to: APP_CONFIG['password_reset_email_sender'],
          subject: "#{@system_name} - Reset password instructions")
  end

  private

  def mail(headers, &block)
    #TODO cleanup this legacy class
    #it appears self.default_url_options is pointing at Rails.application.config.action_mailer.default_url_options
    #hence only update if not nil
    self.default_url_options[:host] = @host_url unless @host_url.nil?
    super
  end

end
