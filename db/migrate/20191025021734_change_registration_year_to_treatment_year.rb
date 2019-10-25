class ChangeRegistrationYearToTreatmentYear < ActiveRecord::Migration[5.0]
  def change
    rename_column :survey_configurations, :start_year_of_registration, :start_year_of_treatment
    rename_column :survey_configurations, :end_year_of_registration, :end_year_of_treatment
  end
end
