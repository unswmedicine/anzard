class CreateClinicAllocations < ActiveRecord::Migration[5.0]
  def change
    create_table :clinic_allocations do |t|
      t.belongs_to :clinic, index: true
      t.belongs_to :user, index: true
      t.timestamps
    end

    change_table :users do |t|
      t.remove :clinic_id
    end
  end
end
