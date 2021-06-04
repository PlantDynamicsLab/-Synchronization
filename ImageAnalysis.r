##ANALIZE THE ROI SELECTED OF EVERY IMAGE IN IMAGEJ

#Data as csv using as "," to separate entries. Frames in rows and ROIs in columns

#Packages require
require(dplyr)
require(ggplot2)
require(pracma)


#Folders needed for the analysis

folder = "E:/ImageAnalisys" #Path to the general folder
foldercsv = "E:/ImageAnalisys/Data" #Folder that contains the csv files
finalResults = "E:/ImageAnalisys/FinalResults"#Folder that will contain the results

#List of csv files with intensities 
files = list.files(path = foldercsv, pattern = "csv")

#Readign the option file
option = read.csv("E:\\ImageAnalisys\\FijiAn\\options.csv", header=FALSE)

#Taking the options from options file (same as for fiji processing)
timelapse = option[8,2] #timelapse in minutes
period = option[9,2] #period in minutes
frames = (option[10,2] * 60) / timelapse #Conversion of time experiment into minutes 
funct = option[11,2]


#Take data from the csv folder created by ImageJ
rawData = data.frame()
for (eachfile in files){

	newPos = read.csv(paste(foldercsv,"/",eachfile,sep=""), header=TRUE)
	
	if (ncol(rawData) > 0){
		rawData = cbind(rawData,newPos[,2:ncol(newPos)])
		if (length(newPos) == 2) { colnames(rawData)[ncol(rawData)]=colnames(newPos)[ncol(newPos)] } #if there is only one roi I have to rename
	} else{
		timeHours = (newPos[,1]*timelapse) / 60 
		rawData = cbind(timeHours,newPos)}
}


#Function used in microfluidics experiment

"function options:
	- 0 -> No function
	- 1 -> square / negative square function
	- 2 -> Custom linear function
	"

if (funct == 1){
	
	framePeriod = period / timelapse
	changeCondition = (framePeriod / 2)
	
	#create the gradient to do the wave plot
	i = 0
	condition = c()
	while (i < frames - framePeriod){
		
		condition = c(condition,rep(0,changeCondition),rep(1,changeCondition))
		
		i = i + framePeriod
	
	}
	
	#this part is to fill the last position so r does not complain because of the lengths
	left = frames - i
	
	if (left >= changeCondition){
	
		condition = c(condition,rep(0,changeCondition),rep(1,left - changeCondition))
	
	}else{
	
		condition = c(condition,rep(0,left))
		
	}
	
	gradient = data.frame(Time = seq(1,frames,1) , condition )
	gradient = gradient %>% mutate(Time = (Time * timelapse) / 60)
	
	#we include the two syringes so there is no doubt what we used
	gradient$condition = abs(gradient$condition - 1)
	gradient = gradient %>% mutate(Condition2 = abs(condition -1))
	colnames(gradient) = c("Time","Condition1","Condition2")
	
	#create the data frame to fill the background of the image
	start = seq(1,frames,changeCondition)
	end = c(seq(1 + changeCondition,frames,changeCondition),frames)
	
	if (length(start) %% 2 > 0){
	
		state = c(rep(c("Cond1","Cond2"),length(start)/2),"Cond1")
		backGraph = data.frame(start,end,state)
	
	}else{backGraph = data.frame(start,end,state = rep(c("Cond1","Cond2")))}
	
	backGraph = backGraph %>% mutate(start = (start * timelapse) / 60) 
	backGraph = backGraph %>% mutate(end = (end * timelapse) / 60)
	write.csv(backGraph,paste(finalResults,"/Conditions_table.csv",sep=""),row.names = FALSE)	

} else if (funct == 2) {
	
	cycleConds = c(seq(0,1,length = (period / 2)/ timelapse),seq(1,0,length = (period / 2) / timelapse))
	
	#create the gradient to do the custom linear plot
	i = 0
	condition = c()
	while (i < frames - length(cycleConds)){
		
		condition = c(condition,cycleConds)
		
		i = i + length(cycleConds)
	
	}
	
	#this part is to fill the last position so r does not complain because of the lengths
	left = frames - i
	
	if (left >= length(cycleConds)){
	
		condition = c(condition,cycleConds)
	
	}else{
	
		condition = c(condition,cycleConds[1:left])
		
	}

	gradient = data.frame(Time = seq(1,frames,1) , condition )
	gradient = gradient %>% mutate(Time = (Time * timelapse) / 60)
	gradient = gradient %>% mutate(Condition2 = abs(condition -1))
	colnames(gradient) = c("Time","Condition1","Condition2")
	gradient = gradient %>% mutate(aux = 1.1)

	#create the data frame to fill the background of the image


}


#Process data to have nice patterns and normalized
processData = rawData
periodAmplitud = data.frame(matrix(ncol = 4, nrow = 0))
colnames(periodAmplitud) = c("Position","Period","std","Amplitud")

nUpsDowns = 3
allDistances = c()
allAmplitud = c()

for (i in 3:length(processData)){
	
	processData[,i] = detrend(processData[,i])
	processData[,i] = savgol(processData[,i],7)
	
	processData[,i] = processData[,i] + abs(min(processData[,i]))
	processData[,i] = processData[,i] / max(processData[,i])
	
	#Finding the peaks
	peaks = findpeaks(processData[,i],nups = nUpsDowns, ndowns = nUpsDowns) 
	
	if (length(peaks[,1])>2){
		peaks = data.frame(peakFrame = peaks[,2], amplitud = peaks[,1])
	
	
	#Calculating period
		distances = c() #empty distances array
		for (j in 1:length(peaks[,1])-1){
			distances = c(distances,(((peaks[j+1,1]-peaks[j,1]) * timelapse) / 60))
		} #Calculate distances between peaks and we get the result in hours
	
		allDistances = c(allDistances,distances)
		allAmplitud = c(allAmplitud,peaks[,2])
	
		#Add the new period as mean of distances
		periodAmplitud[nrow(periodAmplitud) + 1,] = c(colnames(processData)[i],mean(distances),std(distances),mean(peaks[,2]),0)
	}
}

if (length(peaks[,1]) > 2){
	allDistances = data.frame(allDistances)
	allAmplitud = data.frame(allAmplitud)

	periodAmplitud$Period = as.numeric(periodAmplitud$Period)
	periodAmplitud$std = as.numeric(periodAmplitud$std)
	periodAmplitud$Position = as.factor(periodAmplitud$Position)
	periodAmplitud$Amplitud = as.numeric(periodAmplitud$Amplitud)
}

#Creating graphs

##1.- graphs of the process data
for (i in 3:length(processData)){

	if (funct == 1) {
		ggplot()+geom_line(data=processData,aes(x=processData[,1], y=processData[,i]),col="black", size = 1) + 
		geom_rect(data = backGraph %>% filter(start > processData[1,1]-0.5, end <= 0.5+processData[nrow(processData),1]), aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf, fill = state), alpha = 0.4)	+
		scale_fill_manual(values =c("Cond1" = "grey80", "Cond2" = "grey55")) + theme_classic() + 
		labs ( title = colnames(processData)[i], x = "Time (hours)", y = "Fluorescence") 
	
	} else if (funct == 2) {
		ggplot()+geom_line(data=processData,aes(x=processData[,1], y=processData[,i]),col="black", size = 1) + 
		geom_tile(data=gradient %>% filter(Time > processData[1,1]-4, Time <= 4+processData[nrow(processData),1]),aes(x=Time,y=aux, fill=Condition1, height = 0.1)) + 
		scale_fill_gradient2(mid = "white", high = "black") + theme_classic() + 
		labs ( title = colnames(processData)[i], x = "Time (hours)", y = "Fluorescence")
	
	
	}
	ggsave(paste(folder,"/graphs/",colnames(processData)[i],".pdf", sep = ""),device = "pdf")
}

if (length(peaks[,1]) > 2){

	#2.- graph of period (mean and std)
	ggplot() + geom_bar(data=periodAmplitud,aes(x=Position,y=Period),stat="identity", color="grey80") + 
	geom_errorbar(data = periodAmplitud,aes(x = Position,ymin=Period-std, ymax=Period+std), width=.2) + 
	theme_classic() + labs(y="Period (hours)")+ ylim(c(0,max(periodAmplitud$Period)*1.5))

	ggsave(paste(folder,"/graphs/Periods_means.pdf", sep = ""),device = "pdf")

	#3.- histogram of periods
	ggplot() + geom_histogram(data=allDistances, aes(allDistances),bins=20,col="black") + 
	xlim(xmin=0,xmax=3) + labs(x="Period (hours)") + theme_classic()

	ggsave(paste(folder,"/graphs/Periods_Histogram.pdf", sep = ""),device = "pdf")

	#4.- histogram of amplituds
	ggplot() + geom_histogram(data=allAmplitud, aes(allAmplitud),bins=20,col="black") + 
	xlim(xmin=0,xmax=1.2) + labs(x="Amplitud") + theme_classic()

	ggsave(paste(folder,"/graphs/Amplitud_Histogram.pdf", sep = ""),device = "pdf")

	#5.- graph of period vs Amplitud
	ggplot() + geom_point(data=periodAmplitud,aes(x=Period,y=Amplitud)) + theme_classic() + 
	labs(x="Mean Periods(hours)",y="Mean Amplituds") + xlim(xmin=0,xmax=3) + ylim(ymin=0,ymax=1.2)

	ggsave(paste(folder,"/graphs/AmplitudVSPeriod.pdf", sep = ""),device = "pdf")

	#Write csv files

	write.csv(periodAmplitud,paste(finalResults,"/MeansPeriods_Table.csv",sep=""),row.names = FALSE)
	write.csv(allDistances,paste(finalResults,"/allDistances.csv",sep=""),row.names = FALSE)
	write.csv(allAmplitud,paste(finalResults,"/allAmplitud.csv",sep=""),row.names = FALSE)
}

write.csv(processData,paste(finalResults,"/ProcessData.csv",sep=""),row.names = FALSE)
write.csv(rawData,paste(finalResults,"/RawData.csv",sep=""),row.names = FALSE)
write.csv(gradient,paste(finalResults,"/Conditions.csv",sep=""),row.names = FALSE)


#remove(eachfile,rawData,option)

	
	
	
	
	
	
	
	
	
	
	
	
	
	




