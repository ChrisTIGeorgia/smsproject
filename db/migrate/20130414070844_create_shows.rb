class CreateShows < ActiveRecord::Migration
  def change
    create_table :shows do |t|
	  t.boolean :is_active
	  t.integer :show_duration_minutes
	  t.integer :num_slides
	  t.datetime :start_time
      t.timestamps
    end
  end
end
