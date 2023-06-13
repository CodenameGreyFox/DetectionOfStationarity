library('move')

rFunction = function(data, errorRange = 0.0001, hourLimit = 24, filt = 0) {
	
	#Splits the stack to account for various individuals
	splitStack <- move::split(data)
	
	#Helper function for the method
	helperFunction = function(splitMoveStack) {
	
		#Initializes the variables
		stopTime <- c()
		stopInd <- c()	
		stopDurationH <- c()
		
		coordinates <- splitMoveStack@coords
		dates <- splitMoveStack@timestamps
		
		#Compares all positions with the last known position
		coordVsLast <- coordinates
		coordVsLast[,1] <- coordinates[,1] - coordinates[nrow(coordinates),1]
		coordVsLast[,2] <- coordinates[,2] - coordinates[nrow(coordinates),2]
		
		#Creates array with TRUE when the distance from the last known location is above the error range
		coordVsLastOverError <- (abs(coordVsLast[,1]) + abs(coordVsLast[,2])) > errorRange

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
	write.csv(output,paste( Sys.getenv("APP_ARTIFACTS_DIR"),"StationaryAnimals.csv",sep=""),row.names = FALSE)
	
	#If filter is above 0, it filters only the stationary individuals
	if(filt > 0) {
		if(length(output$stopInd) > 0 ) {
			return(moveStack(splitStack[output$stopInd], forceTz="UTC"))
		} else {
			return(NULL)
		}
	} else if (filt == 0) { #If 0, works as a pass-through
		return(data)
	} else {#If it is below 0, it filters only the non-stationary individuals
		splitStack[output$stopInd] <- NULL
		if (length(splitStack) >0) {
			return(moveStack(splitStack, forceTz="UTC"))
		} else {
			return(NULL)
		}
	}
}
