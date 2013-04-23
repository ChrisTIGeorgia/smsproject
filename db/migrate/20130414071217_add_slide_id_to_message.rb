class AddSlideIdToMessage < ActiveRecord::Migration
  def change
  	add_column :messages, :slide_id, :integer
  end
end
