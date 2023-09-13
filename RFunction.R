library('move')

#Depending on the filter setting it can output:
# `filt = 0` The original MoveStack in Movebank format. No changes from the input data.
# `filt = 1` Only the individuals that were found to be stationary in a MoveStack in Movebank format.
# `filt = -1` Only the individuals that were found to be non-stationary in a MoveStack in Movebank format. 
#
#errorRange is in meters

rFunction = function(data, errorRange = 10, hourLimit = 24, filt = 0) {
	
	#Splits the stack to account for various individuals
	splitStack <- move::split(data)
	
	#Helper function to calculate distance between two coordinates
	haversine = function(lon1,lat1,lon2,lat2) {
		a = sin((lat1-lat2)* (pi/180)/2)^2 + cos(lat1* (pi/180))*cos(lat2* (pi/180))*sin((lon1-lon2)* (pi/180)/2)^2
		c = 2*atan2(sqrt(a), sqrt(1-a))
		d = 6371000 * c #6371000m is the radius of earth			
		return( d )
	}
	
	#Helper function to analyse the different stacks separately
	helperFunction = function(splitMoveStack) {
	
		#Initializes the variables
		stopTime <- c()
		stopInd <- c()	
		stopDurationH <- c()
		
		coordinates <- splitMoveStack@coords
		dates <- splitMoveStack@timestamps
		crs <- splitMoveStack@proj4string

		if (grepl( "+proj=longlat ", crs, fixed = TRUE)) {#If the projection is in degrees

			#Creates array with TRUE when the distance from the last known location is above the error range, converting the distances in degrees to meters
			coordVsLastOverError <- haversine( coordinates[,1], coordinates[,2], coordinates[nrow(coordinates),1],coordinates[nrow(coordinates),2])  > errorRange	
			
		} else { #Assume it is in meters
				coordVsLast <- coordinates
				coordVsLast[,1] <- coordinates[,1] - coordinates[nrow(coordinates),1]
				coordVsLast[,2] <- coordinates[,2] - coordinates[nrow(coordinates),2]
				
				#Creates array with TRUE when the distance from the last known location is above the error range
				coordVsLastOverError <- (abs(coordVsLast[,1]) + abs(coordVsLast[,2])) > errorRange				
		}

		#Gets position of latest position considered as movement
		if(length(which(coordVsLastOverError)) != 0) {		#If it moved at least once
			lastMov <- max(which(coordVsLastOverError))
		} else { #Else consider the first step as the stopping point
			lastMov <- 0
		}
		#Gets date of latest movement and last known position and checks how much time elapsed
		timeToLastMov <- difftime(dates[length(dates)],dates[lastMov+1], units = "hours")
		
		#If more time than the hourLimit has elapsed since the tag stopped moving, adds it to the list
		if(timeToLastMov > hourLimit) {
			stopTime <- append(stopTime,dates[lastMov+1])
			stopInd <- append(stopInd,namesIndiv(splitMoveStack))
			stopDurationH <- append(stopDurationH,timeToLastMov)
		}
		
		return(data.frame(stopInd,stopTime,stopDurationH,row.names=NULL))
	}
	
	output <- lapply(splitStack,helperFunction)	
	
	#Gathers the results in a data frame
	output <- do.call("rbind", output)
	
	#Writes the csv
	write.csv(output,paste(Sys.getenv("APP_ARTIFACTS_DIR"),"StationaryAnimals.csv",sep=""),row.names = FALSE)
	
	#If filter is above 0, it filters only the stationary individuals
	if(filt > 0) {
		if(length(output$stopInd) > 0 ) {
			return(moveStack(splitStack[output$stopInd], forceTz="UTC"))
		} else {
			logger.info("No stationary individuals detected, returning NULL.")
			return(NULL)
		}
	} else if (filt == 0) { #If 0, works as a pass-through
		return(data)
	} else {#If it is below 0, it filters only the non-stationary individuals
		splitStack[output$stopInd] <- NULL
		if (length(splitStack) >0) {
			return(moveStack(splitStack, forceTz="UTC"))
		} else {
			logger.info("No non-stationary individuals detected, returning NULL.")
			return(NULL)
		}
	}
}
