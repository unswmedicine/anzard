class CreateCapturesystemSurveys < ActiveRecord::Migration[5.0]
  def change
    create_table :capturesystem_surveys do |t|
      t.belongs_to :capturesystem
      t.belongs_to :survey

      t.index [:capturesystem_id, :survey_id], unique: true
      t.index [:survey_id, :capturesystem_id], unique: true

      t.timestamps
    end
  end
end
