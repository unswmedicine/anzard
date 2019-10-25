class CreateSurveyConfigurations < ActiveRecord::Migration[5.0]
  def change
    create_table :survey_configurations do |t|
      t.belongs_to :survey
      t.integer :start_year_of_registration
      t.integer :end_year_of_registration
      t.timestamps
    end
  end
end
