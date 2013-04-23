class Show < ActiveRecord::Base
	has_many :slides
	attr_accessible :is_active,
	  :show_duration_minutes,
	  :num_slides
end
