#Once selected the positions and the rois, run this code to obtain the csv filess

import sys  
reload(sys)  
sys.setdefaultencoding('utf8')

from ij import IJ, ImagePlus
from ij.io import FileSaver
import os 
import re
from ij.process import ImageStatistics as IS
from ij.gui import Roi, OvalRoi, Toolbar 
from ij.plugin.frame import RoiManager
from ij.measure import Measurements
from ij import WindowManager
from ij.measure import Measurements
import csv
from ij.gui import Overlay
from java.awt import Font
from ij.gui import TextRoi
from java.awt import Color
from array import zeros
from ij.process import FloatProcessor

#--- FUNCTIONS ---#
def getRoilist(roi):

	#Load the RoiList for every trap

	IJ.run("ROI Manager...")
	rm = RoiManager.getInstance()
	rm.reset()

	rm.runCommand("Open",roi)

	roi_list = rm.getRoisAsArray()

	return(roi_list)
	
	

def getIntensities(imp , roi_list):

	#Obtain fluorescence intensities for every ROI

	n_slice = imp.getNFrames()
	if n_slice == 1:
		n_slice = imp.getNSlices()

	#Select the image
	stack = imp.getImageStack()
	calibration = imp.getCalibration()
	
	Intensities = []
	
	#Iteration over the frames
	for i in range(0 , n_slice):
		
		ip = stack.getProcessor(i + 1)
		
		frame = []
		
		#Iteration over the rois in each frame to take the fluorescence mean
		for roi in roi_list:
			
			ip.setRoi(roi)
			
			stats = IS.getStatistics(ip , Measurements.MEAN , calibration)
			mean = stats.mean
			
			frame.append(mean)
		
		Intensities.append(frame)
	
	return Intensities

def WriteCsvFile(printfile , title , folder):

	#Write the output CSV file

	with open(folder+"\\"+title+".csv" , 'w') as csvfile:
		writer = csv.writer(csvfile,delimiter=",")
		writer.writerows(printfile)

#Paths of the folders needed to run the script
folder = "E:\ImageAnalisys\Images" #Folder that contains the position folders
dataFolder = "E:\ImageAnalisys\Data" #Folder where script will create the results
optionsFile = "E:\ImageAnalisys\FijiAn\options.csv" #File with the options 



#Upload of the option file
options = []

#in case there is no option file, program will STOP
try:
	with open(optionsFile , "rb") as csvfile:
		spamreader = csv.reader(csvfile , delimiter = "," ,)
		for row in spamreader:
			options.append(row[1])
	
	#It takes channels used from option file
	channels = []
	for i in range(2,2+int(options[0]-1)):
		channels.append(options[i]) # 0 for DIC, 1 for green and 2 for red

	backGround = options[1+int(options[0])]
	start = int(options[2+int(options[0])])
	end = int(options[3+int(options[0])]) - int(options[2+int(options[0])])
	
except:
	sys.exit("Options file must be in the folowing path: " + optionsFile)


##in case there is no image folder, program will STOP
if os.path.exists(folder):
	pass
else:
	os.mkdir(folder)
	sys.exit("folder "+folder+" has been created. Your images shold be here")

if os.path.exists(dataFolder):
	pass
else:
	os.mkdir(dataFolder)

#Upload list of folder positions
positions = os.listdir(folder)

for position in os.listdir(folder):
	
	#For each position it upload the ROIs
	for filename in os.listdir(folder+'\\'+position):
		if filename.find("RoiSet.zip") >= 0: 
			roiname = folder+'\\'+position+'\\'+filename
			print roiname
			rois = getRoilist(roiname) 
		
	#it opens Green and Red channels
	for channel in channels: 
		IJ.run("Image Sequence...", "open="+folder+"/"+position+"/img_channel00"+channel+"_position000_time000000000_z000.tif number="+str(end)+" starting="+str(start)+" file=channel00"+channel+" sort")
		image = IJ.getImage()

		#get the intensities in the different channels
		if int(channel) == int(channels[0]):
			greenResults = getIntensities(image,rois)
			
			
		elif int(channel) == int(channels[1]):
			redResults = getIntensities(image,rois)
			
		#Close image sequenced once measure is done	
		IJ.selectWindow(image.title)
		IJ.run("Close")

	header = ["Frame"]
	for i in range(0,len(greenResults[i])):
		header.append(position+"_"+str(i))
	
	results = [header]

	#Normalize the results to the red channel
	for i in range(0,len(greenResults)):
		aux = [i+start]
		for j in range(0,len(greenResults[i])):

			if redResults[i][j] < int(backGround):
				aux.append(0)
			else: 
				aux.append(greenResults[i][j] / (greenResults[i][j] + redResults[i][j]))
		
		results.append(aux)




	WriteCsvFile(results,position,dataFolder)
	

print "Finished"




