class RootController < ApplicationController
	
	def index
		redirect_to :action => :liveShow
	end
	
	def admin
		@user = User.find(:all)
		@shows = Show.find(:all)
	end
	
	def addMessage

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
		#get dara
		number = params[:from]
		message = params[:message]
		secret = params[:phone_number]
		success = "false"
		
		puts secret
		if secret == "555666777"	
			puts "INS"
			slideInfo = getActiveSlide()
			currentSlide = slideInfo[0]
			if currentSlide
				currentShow = Show.last
				
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
					newMessage = Message.new
					newMessage.user_id = currentUser.id
					newMessage.body = message
					newMessage.time_recieved = DateTime.now
					newMessage.slide_id = currentShow.slides[currentSlide].id
					#check for recent messages
					secPerSlide = getSecondsPerSlide(currentShow)
					minSeperation = 2.0/secPerSlide
					currentDuration = slideInfo[1]
					safeTime = currentDuration - minSeperation
					recentMessage = Message.where("slide_id = ? AND slide_time > ?",newMessage.slide_id,safeTime).last
					if recentMessage
						newTime = recentMessage.slide_time + minSeperation
						if (secPerSlide - (1.0-newTime)*secPerSlide) > 1.0
							newMessage.slide_time = newTime
						else
							#too late ignore this time but store incase we want it later
							newMessage.slide_time = 1.1
						end
					else
						newMessage.slide_time = slideInfo[1]
					end
					newMessage.save
				end
			end
			success = "true"
		end
			
		jsonResponse = '{ "playload": { "success": "'+success+'" } }'
		render :json => jsonResponse
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
