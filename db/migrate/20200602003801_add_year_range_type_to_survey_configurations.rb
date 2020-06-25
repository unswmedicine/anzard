class AddYearRangeTypeToSurveyConfigurations < ActiveRecord::Migration[5.0]
  def change
    add_column :survey_configurations, :year_range_type, :string, default: 'C'
  end
end
