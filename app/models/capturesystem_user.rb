class CapturesystemUser < ApplicationRecord
  belongs_to :capturesystem
  belongs_to :user

  validates_presence_of :capturesystem_id, presence: true
  validates_presence_of :user_id, presence: true
  validates_uniqueness_of :user_id, scope: [:capturesystem_id], message: 'can only belong to a capture system once'
end
