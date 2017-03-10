class ChangeHospitalToClinic < ActiveRecord::Migration[5.0]
  def change
    change_table :hospitals do |t|
      t.remove :abbrev
      t.string :unit
      t.string :site
      t.string :site_name
    end
  end
end