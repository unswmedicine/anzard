class RenameHospitalToClinic < ActiveRecord::Migration[5.0]
  def change
    rename_table :hospitals, :clinics
    rename_column :clinics, :name, :unit_name
    rename_column :clinics, :unit, :unit_code
    rename_column :clinics, :site, :site_code

    rename_column :users, :hospital_id, :clinic_id
    rename_column :responses, :hospital_id, :clinic_id
    rename_column :batch_files, :hospital_id, :clinic_id
  end
end
