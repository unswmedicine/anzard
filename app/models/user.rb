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

class User < ApplicationRecord

  STATUS_UNAPPROVED = 'U'
  STATUS_ACTIVE = 'A'
  STATUS_DEACTIVATED = 'D'
  STATUS_REJECTED = 'R'

  # Include devise modules
  devise :database_authenticatable, :registerable, :lockable, :recoverable, :trackable, :validatable, :timeoutable

  belongs_to :role
  has_many :responses
  has_many :clinic_allocations
  has_many :clinics, through: :clinic_allocations
  has_many :capturesystem_users
  has_many :capturesystems, through: :capturesystem_users

  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :status
  validates_presence_of :clinics, unless: Proc.new { |user|  user.role.blank? || user.super_user? }

  validates_length_of :first_name, maximum: 255
  validates_length_of :last_name, maximum: 255
  validates_length_of :email, maximum: 255

  validates_numericality_of :allocated_unit_code, greater_than_or_equal_to: 0, allow_nil: true

  with_options if: :password_required? do |v|
    v.validates :password, password_format: true
  end

  before_validation :initialize_status
  before_validation :clear_super_user_clinic

  scope :pending_approval, -> {where(status: STATUS_UNAPPROVED).order(:email)}
  scope :approved, -> {where(status: STATUS_ACTIVE).order(:email)}
  scope :deactivated_or_approved, -> {where("status = 'D' or status = 'A' ")}
  scope :approved_superusers, -> {joins(:role).merge(User.approved).merge(Role.superuser_roles)}

  # Override Devise active for authentication method so that users must be approved before being allowed to log in
  # https://github.com/plataformatec/devise/wiki/How-To:-Require-admin-to-activate-account-before-sign_in
  def active_for_authentication?
    super && approved?
  end

  # Override Devise method so that user is actually notified right after the third failed attempt.
  def attempts_exceeded?
    self.failed_attempts >= self.class.maximum_attempts
  end

  # Overrride Devise method so we can check if account is active before allowing them to get a password reset email
  # https://github.com/plataformatec/devise/blob/v4.2.0/lib/devise/models/recoverable.rb#L44
  def send_reset_password_instructions
    if approved?
      token = set_reset_password_token
      send_reset_password_instructions_notification(token)

      token
    else
      if pending_approval? or deactivated?
        Notifier.notify_user_that_they_cant_reset_their_password(self, 'NPESU').deliver
      end
    end
  end

  # Custom method overriding update_with_password so that we always require a password on the update password action
  # Devise expects the update user and update password to be the same screen so accepts a blank password as indicating that
  # the user doesn't want to change it
  def update_password(params={})
    current_password = params.delete(:current_password)

    result = if valid_password?(current_password)
               update_attributes(params)
             else
               self.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
               self.attributes = params
               false
             end

    clean_up_passwords
    result
  end

  # Override devise method that resets a forgotten password, so we can clear locks on reset
  def reset_password!(new_password, new_password_confirmation)
    self.password = new_password
    self.password_confirmation = new_password_confirmation
    clear_reset_password_token if valid?
    if valid?
      unlock_access! if access_locked?
    end
    save
  end

  # Overriding Send unlock instructions by email
  def send_unlock_instructions
    raw, enc = Devise.token_generator.generate(self.class, :unlock_token)
    self.unlock_token = enc
    save(validate: false)
    #send_devise_notification(:unlock_instructions, raw, {})
    raw
  end

  def approved?
    self.status == STATUS_ACTIVE
  end

  def approved_in_capturesystem?(capturesystem)
    self.approved? && !self.capturesystem_users.find_by(capturesystem: capturesystem, access_status: CapturesystemUser::STATUS_ACTIVE).nil?
  end

  def pending_approval?
    self.status == STATUS_UNAPPROVED
  end
  def pending_approval_in_capturesystem?(capturesystem)
    self.pending_approval? || !self.capturesystem_users.find_by(capturesystem: capturesystem, access_status: CapturesystemUser::STATUS_UNAPPROVED).nil?
  end

  def deactivated?
    self.status == STATUS_DEACTIVATED
  end
  def deactivated_in_capturesystem?(capturesystem)
    self.deactivated? || !self.capturesystem_users.find_by(capturesystem: capturesystem, access_status: CapturesystemUser::STATUS_DEACTIVATED).nil?
  end


  def rejected?
    self.status == STATUS_REJECTED
  end
  def rejected_in_capturesystem?(capturesystem)
    self.rejected? || !self.capturesystem_users.find_by(capturesystem: capturesystem, access_status: CapturesystemUser::STATUS_REJECTED).nil?
  end

  def deactivate
    self.status = STATUS_DEACTIVATED
    save!(validate: false)
  end

  def deactivate_in_capturesystem(capturesystem)
    self.capturesystem_users.where(capturesystem: capturesystem).update(access_status: CapturesystemUser::STATUS_DEACTIVATED)
  end


  def activate
    self.status = STATUS_ACTIVE
    save!(validate: false)
  end

  def activate_in_capturesystem(capturesystem)
    self.capturesystem_users.where(capturesystem: capturesystem).update(access_status: CapturesystemUser::STATUS_ACTIVE)
  end

  def approve_access_request(system_name, system_base_url, capturesystem)
    self.status = STATUS_ACTIVE
    save!(validate: false)
    CapturesystemUser.where(user:self, capturesystem:capturesystem).update(access_status:CapturesystemUser::STATUS_ACTIVE)

    # send an email to the user
    Notifier.notify_user_of_approved_request(self, system_name, system_base_url, capturesystem).deliver
  end

  def reject_access_request(system_name, capturesystem)
    self.status = STATUS_REJECTED
    save!(validate: false)
    #reject as spam will keep the above user and prevent it from register again, and prevent it from access all the capture systems
    CapturesystemUser.where(user:self, capturesystem:capturesystem).update(access_status:CapturesystemUser::STATUS_REJECTED)

    # send an email to the user
    Notifier.notify_user_of_rejected_request(self, system_name, capturesystem).deliver
  end

  #deprecated
  #def notify_admin_by_email( system_name, system_base_url)
    #Notifier.notify_superusers_of_access_request(self, system_name, system_base_url).deliver
  #end

  #deperated
  def check_number_of_superusers(id, current_user_id)
    current_user_id != id.to_i or User.approved_superusers.length >= 2
  end

  #deprecated
  def self.get_superuser_emails
    approved_superusers.collect { |u| u.email }
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def super_user?
    return false unless self.role.present?
    self.role.super_user?
  end

  #class method to do the same thing
  def self.super_user? (user)
    return false unless user.role.present?
    user.role.super_user?
  end

  def authenticatable_salt
    "#{super}#{session_token}"
  end

  def invalidate_sessions!
    self.update(session_token: SecureRandom.hex(16))
  end

  private

  def clear_super_user_clinic
    if self.super_user?
      self.clinics.clear
      self.allocated_unit_code = nil
    end
  end

  def initialize_status
    self.status = STATUS_UNAPPROVED unless self.status
  end

end
