class Message < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :user
  belongs_to :slide
  
  attr_accessible :user_id,
 	:body,
 	:time_recieved,
 	:slide_id
 	
 	validates :user_id, :body, :time_recieved, :presence => true
end
