class CreateTimeSlots < ActiveRecord::Migration[7.0]
  def change
    create_table :time_slots do |t|
      t.date :slot_date, null: false
      t.string :start_time, null: false
      t.string :end_time, null: false
      t.string :status, null: false
      t.boolean :is_booked, :default => false
      t.string :person_name
      t.string :person_number
      t.timestamps
    end
  end
end
