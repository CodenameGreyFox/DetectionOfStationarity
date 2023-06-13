# Detection Of Stationarity

*This app has been created for the EMAC23 coding challenge*

MoveApps

Github repository: https://github.com/CodenameGreyFox/DetectionOfStationarity

## Description
An app to detect when an individual has become stationary and is no longer moving.

## Documentation
This app detects when an individual has become stationary and is no longer moving by comparing its last known position with the last movement it made from that position.
The individual is considered to have moved from position A to B if `abs(Xa-Xb)+ abs(Ya-Yb)` is bigger than the provided allowable GPS error (default 0.0001).
The individual is considered stationary if the difference in hours from its last known position and last known movement is bigger than the provided hour limit (default 24 hours).

### Input data
MoveStack in Movebank format.

### Output data
Depending on the filter setting it can output:
* `Filter = 0` The original MoveStack in Movebank format. No changes from the input data.
* `Filter = 1` Only the individuals that were found to be stationary in a MoveStack in Movebank format.
* `Filter = -1` Only the individuals that were found to be non-stationary in a MoveStack in Movebank format. 
*
### Artefacts
* `StationaryAnimals.csv`: csv-file with Table of all individuals that were found to be stationary. It has three rows:

		* stopInd - Identification of the stationary individual.
		* stopTime - Time from which the individual was considered stationary. (yyyy-MM-dd H:m:s)
		* stopDurationH - Number of hours the individual has been stationary.

### Settings 

* `Allowable GPS Error`: The maximum distance from two points that is not considered movement, due to GPS inaccuracy. Unit: `Same as the CRS of the data`.
* `Hours Until Stationary`: The minimum time needed for the individual to be immobile for it to be considered stationary. Unit: `hours`.
* `Filter Results?`: 0 = Serves as a pass-through; 1 = Only returns stationary individuals; -1 = Only returns non-stationary individuals.

### Most common errors
None at present.

### Null or error handling
If no individuals are found to be stationary, it returns an empty .csv file.
If using filter, and no individuals match the criteria, returns NULL instead of a MoveStack.

* **Setting `Allowable GPS Error`:** If not given it defaults to 0.0001.
* **Setting `Hours Until Stationary`:** If not given it defaults to 24.
* **Setting `Filter Results?`:** If not given it defaults to 0 (pass-through).

