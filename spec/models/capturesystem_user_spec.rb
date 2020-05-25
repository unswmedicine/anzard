require 'rails_helper'

RSpec.describe CapturesystemUser, type: :model do
  describe "Associations" do
    it { expect have_many(:capturesystem)}
    it { expect have_many(:user)}
  end

  describe "Validations" do
    it { expect validate_presence_of(:capturesystem_id)}
    it { expect validate_presence_of(:user_id)}
    it { expect validate_uniqueness_of(:capturesystem_id).scoped_to(:user_id)}
  end
end
