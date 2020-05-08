class CapturesystemUser < ApplicationRecord
  STATUS_UNAPPROVED = 'U'
  STATUS_ACTIVE = 'A'
  STATUS_DEACTIVATED = 'D'
  STATUS_REJECTED = 'R'

  belongs_to :capturesystem
  belongs_to :user

  validates_presence_of :capturesystem_id, presence: true
  validates_presence_of :user_id, presence: true
  validates_uniqueness_of :user_id, scope: [:capturesystem_id], message: 'can only belong to a capture system once'
  validates_presence_of :access_status

  before_validation :initialize_status


  private

  def initialize_status
    self.access_status = STATUS_UNAPPROVED if self.access_status.blank?
  end
end
