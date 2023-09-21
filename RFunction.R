library('move2')
library('units')
library('sf')

#Depending on the filter setting it can output:
# `filt = 0` The original MoveStack in Movebank format. No changes from the input data.
# `filt = 1` Only the individuals that were found to be stationary in a MoveStack in Movebank format.
# `filt = -1` Only the individuals that were found to be non-stationary in a MoveStack in Movebank format. 
#
#errorRange is in meters
rFunction = function(data, errorRange = 10, hourLimit = 24, filt = 0) {
	
	#Splits the stack to account for various individuals
	splitStack <- split(data, mt_track_id(data))

	#Helper function to analyse the different stacks separately
	helperFunction = function(splitMoveStack) {
	
		#Initializes the variables
		stopTime <- c()
		stopInd <- c()	
		stopDurationH <- c()
		
		dates <- mt_time(splitMoveStack)
		crs <- sf::st_crs(splitMoveStack)

		#Creates array with TRUE when the distance from the last known location is above the error range, converting the distances in degrees to meters
		coordVsLastOverError <- set_units(st_distance(st_geometry(splitMoveStack),st_geometry(splitMoveStack)[nrow(splitMoveStack)]),"m")
		coordVsLastOverError <- coordVsLastOverError > set_units(errorRange,"m")

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
			stopInd <- append(stopInd,unique(mt_track_id(splitMoveStack)))
			stopDurationH <- append(stopDurationH,timeToLastMov)
		}
		
		return(data.frame(stopInd,stopTime,stopDurationH,row.names=NULL))
	}
	
	output <- lapply(splitStack,helperFunction)	
	
	#Gathers the results in a data frame
	output <- do.call("rbind", output)
	
	#Writes the csv
	write.csv(output, appArtifactPath("StationaryAnimals.csv"),row.names = FALSE)
	
	#If filter is above 0, it filters only the stationary individuals
	if(filt > 0) {
		if(length(output$stopInd) > 0 ) {
			return(mt_stack(splitStack[output$stopInd]))
		} else {
			logger.info("No stationary individuals detected, returning NULL.")
			return(NULL)
		}
	} else if (filt == 0) { #If 0, works as a pass-through
		return(data)
	} else {#If it is below 0, it filters only the non-stationary individuals
		splitStack[output$stopInd] <- NULL
		if (length(splitStack) >0) {
			return(mt_stack(splitStack))
		} else {
			logger.info("No non-stationary individuals detected, returning NULL.")
			return(NULL)
		}
	}
}
