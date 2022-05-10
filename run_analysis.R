library(data.table)
library(dplyr)
library(tidyr)
library(readr)


## Load all datasets
datafolder <- "UCI HAR Dataset/"

trainfeature <- fread(file = paste(datafolder, "train/X_train.txt", sep = ""))
trainlabel <- fread(file = paste(datafolder, "train/y_train.txt", sep = ""))
trainsubject <- fread(file = paste(datafolder, "train/subject_train.txt", sep = ""))

testfeature <- fread(file = paste(datafolder, "test/X_test.txt", sep = ""))
testlabel <- fread(file = paste(datafolder, "test/y_test.txt", sep = ""))
testsubject <- fread(file = paste(datafolder, "test/subject_test.txt", sep = ""))

featurenames <- fread(file = paste(datafolder, "features.txt", sep = ""))
labelnames <- fread(file = paste(datafolder, "activity_labels.txt", sep = ""))


#------------------------------------------
## Combine train and test datasets (measurements, activity labels and subject ids)
combfeature <- bind_rows(trainfeature, testfeature)
comblabels <- bind_rows(trainlabel, testlabel)
combsubject <- bind_rows(trainsubject, testsubject)

## Remove from environment the train and test datasets
rm(trainfeature, testfeature, trainlabel, testlabel, trainsubject, testsubject)


#------------------------------------------
## Rename activity label and names in concerned datasets : "V1", "V2" => "label", "activity"
colnames(labelnames) <- c("label", "activity")
colnames(comblabels) <- "label"

# Rename subject ids column : "V1" => "subjectid"
colnames(combsubject) <- "subjectid"

# Rename columns of the features files : "V1", "V2" => "measurement", "measurementname"
colnames(featurenames) <- c("measurement", "measurementname")


#------------------------------------------
## Merge by label the real data with the activity names
comblabels <- inner_join(comblabels, labelnames)

## Remove from env the activity names info file
rm(labelnames)


#------------------------------------------
## Slice and store in different column the features/measurements names : "tBodyAcc-mean()-X" => "tBodyAcc", "mean()", "X"
cutstrcol <- function(coltosplit){strsplit(coltosplit, "-")}
featurenames <- featurenames %>%
      mutate(feature = unlist(lapply(cutstrcol(measurementname), function(elt){elt[1]})), 
             estimate = unlist(lapply(cutstrcol(measurementname), function(elt){elt[2]})), 
             estimateparameter = unlist(lapply(cutstrcol(measurementname), function(elt){elt[3]})))

# Delete feature full name column
featurenames[,"measurementname"] <- NULL


#------------------------------------------
## Combine subject ids, activity names and the measurements data
fulldata <- cbind(combsubject, comblabels[,2], combfeature)

## Make tidy data where each parsed features are split and set as a unique variable with corresponding value
fulldata <- fulldata %>% gather(key = measurement, value = value, -(subjectid:activity))
fulldata$measurement <- parse_number(fulldata$measurement)

## Merge working dataset with features/measurements variables names
fulldata <- inner_join(fulldata, featurenames)

## Remove the intermediate "variable" col
fulldata[,"measurement"] <- NULL

## Reorder dataframe
fulldata <- fulldata[, c(1:2,4:6,3)]

## Remove from env the train+test features and labels + measurements variables names
rm(combfeature, comblabels, featurenames)
rm(cutstrcol)


#------------------------------------------
## Search for variables measurements each mean and std calculations
extractdata <- fulldata[!is.na(fulldata$estimate) & (fulldata$estimate == "mean()" | fulldata$estimate == "std()"), ]

## Group previous subseted data by measurement types, activity and subject id
estimategrp <- extractdata %>% group_by(feature, estimateparameter, estimate, activity, subjectid)

##  Tidy data set with the average of each variable for each activity and each subject
result <- estimategrp %>% summarize(mean(value))

## Export and write in a txt file the dataset
fwrite(x = result, file = "avgMeasures.txt", row.names = FALSE)