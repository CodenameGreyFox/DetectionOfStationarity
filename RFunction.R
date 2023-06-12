library('move')
## The parameter "data" is reserved for the data object passed on from the previous app

## to display messages to the user in the log file of the App in MoveApps one can use the function from the logger.R file: 
# logger.fatal(), logger.error(), logger.warn(), logger.info(), logger.debug(), logger.trace()

rFunction = function(data, errorRange = 0.0001, hourLimit = 24) {

	#Initializes the variables
	stopTime <- c()
	stopInd <- c()	
	stopDurationH <- c()
	
	#Splits the stack to account for various individuals
	splitMoveStack <- move::split(data)
	
	#Does the calculations for each individual separately
	for(ind in 1:length(namesIndiv(data))) {
		
		coordinates <- splitMoveStack[[ind]]@coords
		timeStamps <- splitMoveStack[[ind]]@timestamps
		dates <- as.POSIXct(timeStamps, format="%Y-%m-%d %H:%M:%S", tz="UTC")
		
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
			stopInd <- append(stopInd,namesIndiv(data)[ind])
			stopDurationH <- append(stopDurationH,timeToLastMov)
		}
	}		
	
	#Creates the data frame to be output
	output <- data.frame(stopInd,stopTime,stopDurationH,row.names=NULL)
	write.csv(output,paste( Sys.getenv("APP_ARTIFACTS_DIR"),"StationaryAnimals.csv",sep=""),row.names = FALSE)
	return(data)
}

