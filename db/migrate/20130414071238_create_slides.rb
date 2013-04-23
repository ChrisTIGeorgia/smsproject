class CreateSlides < ActiveRecord::Migration
  def change
    create_table :slides do |t|
	  t.integer :show_id
	  t.string :image_path
      t.timestamps
    end
  end
end
