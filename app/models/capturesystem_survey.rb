class CapturesystemSurvey < ApplicationRecord
  belongs_to :capturesystem
  belongs_to :survey

  validates_presence_of :capturesystem_id, presence: true
  validates_presence_of :survey_id, presence: true
  validates_uniqueness_of :survey_id, scope: [:capturesystem_id], case_sensitive: true, message: 'can only belong to a capture system once'
end
