require 'rails_helper'

RSpec.describe CapturesystemSurvey, type: :model do
  describe "Associations" do
    it { expect have_many(:capturesystem)}
    it { expect have_many(:survey)}
  end

  describe "Validations" do
    it { expect validate_presence_of(:capturesystem_id)}
    it { expect validate_presence_of(:survey_id)}
    it { expect validate_uniqueness_of(:capturesystem_id).scoped_to(:survey_id)}
  end

end
