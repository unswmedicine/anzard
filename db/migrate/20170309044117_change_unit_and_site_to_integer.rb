class ChangeUnitAndSiteToInteger < ActiveRecord::Migration[5.0]
  def change
    change_column :hospitals, :unit, :integer
    change_column :hospitals, :site, :integer
  end
end
