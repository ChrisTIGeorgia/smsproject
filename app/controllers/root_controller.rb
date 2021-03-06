class RootController < ApplicationController
	
	def index
		redirect_to :action => :liveShow
	end
	
	def admin
		if params[:pw] == "holidayINN"
			@user = User.find(:all)
			@shows = Show.find(:all)
		else
			redirect_to :action => :index and return
		end
	end
	
	def addMessage
	end

  def randomizeSlides
		currentShow = Show.last
		slides = currentShow.slides
    randomArray = []
    slides.each do |slide|
      randomArray.push(slide.id)
    end
    randomArray = randomArray.shuffle()
    puts randomArray
    return randomArray
  end
	
	def getActiveSlide
		currentShow = Show.last
		slideIndex = nil
		slideDuration = nil
		if currentShow and currentShow.is_active
			timePassed = getCurrentShowDuration(currentShow)
			if timePassed/60 > currentShow.show_duration_minutes
				currentShow.is_active = false
				currentShow.save
        return [nil,nil]
			else
				secondsPerSlide = getSecondsPerSlide(currentShow)
				slideTime = timePassed/secondsPerSlide
				slideIndex = slideTime.to_i
				slideDuration = slideTime%1
			end
		else
      return [nil,nil]
    end
		return [ @@slideArray[slideIndex], slideDuration]
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
		#get data
		number = params[:from]
		message = params[:message]
		secret = params[:phone_number]
		success = "false"
		
		if secret == "555666777"	
			slideInfo = getActiveSlide()
			currentSlide = Slide.find(slideInfo[0])
			if currentSlide
				currentShow = Show.last
				
				currentUser = User.where(:phone_number => number).first
        puts currentUser
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
					newMessage.slide_id = currentSlide.id
					#check for recent messages
					secPerSlide = getSecondsPerSlide(currentShow)
					minSeperation = 10.0/secPerSlide
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
		Show.destroy_all
		redirect_to :action=> :index
	end
	

	def setupShow( duration )
		theShow = Show.last
		if not theShow
			theShow = setupDefaultShow
		end
		theShow.show_duration_minutes = duration
		theShow.save
		return theShow
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
		minutes = params[:mins].to_i
		if minutes < 1
			minutes = 30
		end
		theShow = setupShow(minutes)
		theShow.start_time = DateTime.now
		theShow.is_active = true
		theShow.save
		@@slideArray = randomizeSlides()
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
		if slideInfo[0]
			currentShow = Show.last
      currentSlide = Slide.find(slideInfo[0])
		  currentSlideProgress = slideInfo[1]
			@live = true	
			@current_slide_path = currentSlide.image_path
			latestMesssage = Message.where("slide_id = ? AND slide_time <= ?",currentSlide.id,currentSlideProgress).order("slide_time DESC").first
			@message = latestMesssage
			slideDuration = getSecondsPerSlide(currentShow)
			@timeLeft = (slideDuration - slideDuration*currentSlideProgress).ceil
		else
			@live = false
		end
	end	
end
