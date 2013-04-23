class Slide < ActiveRecord::Base
  # attr_accessible :title, :body
  	belongs_to :show
  	
    attr_accessible :show_id,
    	:image_path
 	
 	validates :image_path, :presence => true
end
