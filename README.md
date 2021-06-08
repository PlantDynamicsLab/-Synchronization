# -Synchronization

##--ImageAnalysis.py and ImageAnalysis.r scripts were written to analyse fluorescence microscopy
for the scientific work entitled "Synchronization of gene expression across eukaryotic communities 
through chemically-controlled hysteresis".--##

An option file is needed to run any of the scripts:

##------OPTION FILE------##
-NChannels --> Number of channel were images are taken.
-DIC, Green, Red --> The order of the channels. ImageAnalysis.py will only use 1 and 2 that must 
						correspond to green and red respectively.
-Background --> It will not consider fluorescence intensity if red signal is below to some threshold.
				*Red fluorescence is used to mark alive cells.
-Start, end --> Start and end frames to be analyse.
-Timelapse --> Frecuency of the imaging in minutes.
-Period --> Period that follows the changing of the inputs in minutes.
-Time Experiment --> Numbre of hours the experiment is running.
-Function type --> Function used in ImageAnalysis.r for input changes.

##------ImageAnalysis.py------##

First script to run. It will measure Green fluorescence intensity and normalize it to Red fluorescence
intensity for every position in every frame.

-Images for every channel and frame must be saved in independent files in a folder named with the position
	that corresponds.
-All positions folders to be analyse must be in the directory that corresponds with the path saved in the 
	folder variable (code line 86).
-Path to the Opion file has to be saved in optionFile variable (code line 88).
-CSV files generated will be generated in the path saved in dataFolder variable (code line 87).

##------ImageAnalysis.r------##

Second and last script to run. It will normalize data to maximum value, detrend and smooth each position. Then
it will calculate period and amplitud of oscillations and finally it will generate graphs for every position.

-folder variable must contain the path the general directory where dataFolder from previous script is.
-foldercsv variable contains the same path as dataFolder.
-Path to the folder where finalResults are generated is saved in finalResults variable.

**IMPORTANT: In order to change peak detection for period calculation. Variable nUpsDowns can be modify in
				code line 150.
				
**IMPORTANT: In order to change smoothness of the curves, savgol second parameter can be modify in code line
				157. Before changing this parameter, it is important to read documentation for this function.
				https://www.rdocumentation.org/packages/pracma/versions/1.9.9/topics/savgol
