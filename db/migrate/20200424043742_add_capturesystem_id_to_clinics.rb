class AddCapturesystemIdToClinics < ActiveRecord::Migration[5.0]
  def change
    add_column :clinics, :capturesystem_id, :integer
    add_index :clinics, [:capturesystem_id, :unit_code, :site_code], unique: true
    #add_index :clinics, [:capturesystem_id, :unit_code]
  end
end
