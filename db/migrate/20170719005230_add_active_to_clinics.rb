class AddActiveToClinics < ActiveRecord::Migration[5.0]
  def change
    add_column :clinics, :active, :boolean, null: false, default: true
  end
end
