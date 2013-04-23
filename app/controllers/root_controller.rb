class RootController < ApplicationController
	
	def index
		redirect_to :action => :liveShow
	end
	
	def admin
		@user = User.find(:all)
		@shows = Show.find(:all)
	end
	
	def addMessage
		newUser = User.new
		newUser.phone_number = "5995005"
		newUser.num_messages = 0
		newUser.save
		newUser.phone_number += newUser.id.to_s
		newUser.save
		
		newMessage = Message.new
		newMessage.save
		newMessage.user_id = newUser.id
		newMessage.body = "THIS IS MESSAGE NUMBER: "
		newMessage.time_recieved = DateTime.now
		newMessage.save
		newMessage.body += newMessage.id.to_s
		newMessage.save
		
		newUser.num_messages += 1
		newUser.save
		redirect_to :action=>'index'
	end
	
	def getActiveSlide
		currentShow = Show.last
		slideIndex = nil
		slideDuration = nil
		if currentShow.is_active
			timePassed = getCurrentShowDuration(currentShow)
			if timePassed/60 > currentShow.show_duration_minutes
				currentShow.is_active = false
				currentShow.save
			else
				secondsPerSlide = getSecondsPerSlide(currentShow)
				slideTime = timePassed/secondsPerSlide
				slideIndex = slideTime.to_i
				slideDuration = slideTime%1
			end
		end
		return [slideIndex, slideDuration]
	end
	
	def getSecondsPerSlide( show )
		showDurationSeconds = show.show_duration_minutes*60
		return showDurationSeconds/show.num_slides
	end
	
	def getCurrentShowDuration( show )
		showStart = show.start_time.to_f
		curTime = DateTime.now.to_f
		timePassed = curTime - showStart
		return timePassed
	end
	
	def submitMessage
		slideInfo = getActiveSlide()
		currentSlide = slideInfo[0]
			if currentSlide
				currentShow = Show.last
				number = params["phone_number"]
				message = params["message"]
				
				currentUser = User.where(:phone_number => number).first
				if not currentUser
					currentUser = User.new
					currentUser.phone_number = number
					currentUser.num_messages = 0
					currentUser.save
				end
				
				currentUser.num_messages += 1
				currentUser.save
				if message
					puts "WE HAVE MESSAGE"
					newMessage = Message.new
					newMessage.user_id = currentUser.id
					newMessage.body = message
					newMessage.time_recieved = DateTime.now
					newMessage.slide_id = currentShow.slides[currentSlide].id
					#check for recent messages
					puts "seconds per slide"
					secPerSlide = getSecondsPerSlide(currentShow)
					puts secPerSlide
					minSeperation = 2.0/secPerSlide
					currentDuration = slideInfo[1]
					puts "minSep: " + minSeperation.to_s
					puts "duration: " + currentDuration.to_s
					safeTime = currentDuration - minSeperation
					puts "safeTime: " + safeTime.to_s
					recentMessage = Message.where("slide_id = ? AND slide_time > ?",newMessage.slide_id,safeTime).last
					if recentMessage
						puts "RECENT"
						newTime = recentMessage.slide_time + minSeperation
						if (secPerSlide - (1.0-newTime)*secPerSlide) > 1.0
							newMessage.slide_time = newTime
						else
							#too late ignore this time but store incase we want it later
							newMessage.slide_time = 1.1
						end
						puts "TRIED TIME"
						puts slideInfo[1]
						puts "NEW TIME"
						puts newMessage.slide_time
					else
						puts "SHOW NOW"
						newMessage.slide_time = slideInfo[1]
					end
					puts "SAVING MESSAGE"
					newMessage.save
				end
			end
		redirect_to :action => :admin
	end
	
	def deleteAll
		User.destroy_all
		Message.destroy_all
		redirect_to :action=> :index
	end
	
	def setupDefaultShow
		newShow = Show.new
		newShow.show_duration_minutes = 30
		newShow.num_slides = 30
		newShow.save
		
		#setup default slides
		for i in (1..newShow.num_slides)
			newSlide = Slide.new
			newSlide.show_id = newShow.id
			path = (i.to_s)+".png"
			newSlide.image_path = path
			newSlide.save
		end
		return newShow
	end
	
	def startShow
		#get last show
		theShow = Show.last
		if not theShow
			theShow = setupDefaultShow
		end
		theShow.start_time = DateTime.now
		theShow.is_active = true
		theShow.save
		redirect_to :action => :admin
	end
	
	def stopShow
		liveShows = Show.where(:is_active => true)
		liveShows.each do |show|
			show.is_active = false
			show.save
		end
		redirect_to :action => :admin
	end
	
	def liveShow
		theShow = Show.where(:is_active => true).last
		if theShow
			@slides = theShow.slides
			@show = theShow
		end
		@poll_duration = 1000
	end
	
	def getCurrentMessage
		slideInfo = getActiveSlide()
		currentSlideIndex = slideInfo[0]
		currentSlideProgress = slideInfo[1]
		if currentSlideIndex
			currentShow = Show.last
			@live = true
			slide = currentShow.slides[currentSlideIndex]
			@current_slide_path = slide.image_path
			latestMesssage = Message.where("slide_id = ? AND slide_time <= ?",slide.id,currentSlideProgress).order("slide_time DESC").first
			@message = latestMesssage
		else
			@live = false
		end
	end	
end
