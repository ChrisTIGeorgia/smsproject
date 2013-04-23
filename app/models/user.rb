class User < ActiveRecord::Base
 # attr_accessible :title, :body
  has_many :messages, :dependent => :destroy
  
  attr_accessible :phone_number,
 	:num_messages
 	
 	validates :phone_number, :presence => true
end
