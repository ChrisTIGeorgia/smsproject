class AddSlideTimeToMessage < ActiveRecord::Migration
  def change
  	add_column :messages, :slide_time, :decimal, :precision => 2, :scale => 3
  end
end
