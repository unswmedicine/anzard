class AddAllocatedUnitCodeToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :allocated_unit_code, :integer
  end
end
