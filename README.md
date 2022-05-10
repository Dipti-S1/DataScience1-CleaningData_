---
title: "ETL : Make tidy data set"
date: 10th May , 2022
output: github_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

*Note : the present markdown is a Rmd file written in Rstudio, then rendered by Knit in a md file, suited for Github visibility, and saved along the twin R markdown file.*

# Purpose overview

This readme file have the purpose to describe the methodology and the code steps of **run_analysis.R** file which return in output a tidy data set formed in the text file **avgMeasures.txt**.  
To get more infos on the variables output of **avgMeasures.txt**, see **variables_codebook.txt**.  
This work is made for the peer-graded assignment course project of the 4th week lesson from the *Getting and Cleaning Data* course by John Hopkins University on coursera plateform.  
The **run_analysis.R** code purpose is to extract and transform data from *Human Activity Recognition Using Smartphones Data Set Version 1.0* research [link](https://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones), source :

Jorge L. Reyes-Ortiz, Davide Anguita, Alessandro Ghio, Luca Oneto.  
Smartlab - Non Linear Complex Systems Laboratory  
DITEN - Università degli Studi di Genova.  
Via Opera Pia 11A, I-16145, Genoa, Italy.  
activityrecognition@smartlab.ws  
www.smartlab.ws

# Summary informations before running the code

## Data

Data folder was download manually as a zip file from the source. Then, it was unzipped manually and directly move in the working directory without any change.

## Snapshots of data frames

In order to show snapshot infos of objects in the running environment will use the above code line. It's only purpose is to give data frame infos in a relatively compact form suited for the present markdwon file. Theses code lines aren't present in **run_analysis.R** and only the output is showed here for better readability.  
The output is a list with 3 explicit attributes which are :  

1. name = the data frame name showed
2. dimensions = the dimensions of the data frame
3. head *or* head_truncated.columns = the first 2 lines of the data frame *or* the first 2 lines and 5 columns of big data frames

```r
list(name = dataframe_show_explicit_name, 
     dimensions = dim(dataframe),
     head = dataframe[1:2,]) ## or head_truncated.columns = dataframe[1:2,1:5])
```

## Running session

### System and IDE info

```{r}
# System info
version
# IDE info :
rstudioapi::versionInfo()$version
```
### Files and folders info

```{r}
# Working directory :
getwd()
# Files in working directory :
list.files(getwd())
# Files in the unziped data source :
list.files("./UCI HAR Dataset")
```
# Code steps

## Libraries loaded

The following packages are loaded :

```{r}
library(data.table)                 ## Mostly used to read txt with fread() faster than read.table(), but could be replaced easily
library(dplyr, warn.conflicts = F)  ## Mostly for merging tables, could be replace with a few more code
library(tidyr)                      ## To make tidy a messy data set
library(readr)                      ## To parse the numeric from a string, could be easily replace
```

## Reading data

All the data is read from **UCI HAR Dataset** folder and store :

```{r}
datafolder <- "UCI HAR Dataset/"
trainfeature <- fread(file = paste(datafolder, "train/X_train.txt", sep = ""))
trainlabel <- fread(file = paste(datafolder, "train/y_train.txt", sep = ""))
trainsubject <- fread(file = paste(datafolder, "train/subject_train.txt", sep = ""))
testfeature <- fread(file = paste(datafolder, "test/X_test.txt", sep = ""))
testlabel <- fread(file = paste(datafolder, "test/y_test.txt", sep = ""))
testsubject <- fread(file = paste(datafolder, "test/subject_test.txt", sep = ""))
featurenames <- fread(file = paste(datafolder, "features.txt", sep = ""))
labelnames <- fread(file = paste(datafolder, "activity_labels.txt", sep = ""))
```

Quick overview on the loaded data sets :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Features data set from training", dimensions = dim(trainfeature), head_truncated.columns = trainfeature[1:2,1:5])
list(name = "Features labels data set from training", dimensions = dim(trainlabel), head = trainlabel[1:2,])
list(name = "Subject ids data set from training", dimensions = dim(trainsubject), head = trainsubject[1:2,])
list(name = "Features data set from testing", dimensions = dim(testfeature), head_truncated.columns = testfeature[1:2,1:5])
list(name = "Features labels data set from testing", dimensions = dim(testlabel), head = testlabel[1:2,])
list(name = "Subject ids data set from testing", dimensions = dim(testsubject), head = testsubject[1:2,])
list(name = "Feature numeric labels and names", dimensions = dim(featurenames), head = featurenames[1:2,])
list(name = "Activity numeric labels and names", dimensions = dim(labelnames), head = labelnames[1:2,])
```

## Construct workable data and store in a single tidy data frame

### Combine train and test datasets (measurements, activity labels and subject ids)

```{r}
combfeature <- bind_rows(trainfeature, testfeature)
comblabels <- bind_rows(trainlabel, testlabel)
combsubject <- bind_rows(trainsubject, testsubject)
```

Quick overview on the merged data sets :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Merged features data sets", dimensions = dim(combfeature), head_truncated.columns = combfeature[1:2,1:5])
list(name = "Merged features labels data sets", dimensions = dim(comblabels), head = comblabels[1:2,])
list(name = "Merged subject ids data sets", dimensions = dim(combsubject), head = combsubject[1:2,])
```

### Set appropriate names for all datasets

```{r}
## Rename activity label and names in concerned datasets : "V1", "V2" => "label", "activity"
colnames(labelnames) <- c("label", "activity")
colnames(comblabels) <- "label"
# Rename subject ids column : "V1" => "subjectid"
colnames(combsubject) <- "subjectid"
# Rename columns of the features files : "V1", "V2" => "measurement", "measurementname"
colnames(featurenames) <- c("measurement", "measurementname")
```

Quick overview on the variables renamed data sets :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Renamed features labels data set", dimensions = dim(comblabels), head = comblabels[1:2,])
list(name = "Renamed subject ids data set", dimensions = dim(combsubject), head = combsubject[1:2,])
list(name = "Renamed feature numeric labels and names", dimensions = dim(featurenames), head = featurenames[1:2,])
list(name = "Renamed activity numeric labels and names", dimensions = dim(labelnames), head = labelnames[1:2,])
```

### Merge by "label" the merged measurements data with the activity names

```{r include=FALSE}
## Merge by label the real data with the activity names
comblabels <- inner_join(comblabels, labelnames)
```

### Slice and store in different column the features/measurements names

The goal here is to split the features names in order get only one variable by column.  
Example : "tBodyAcc-mean()-X" => "tBodyAcc", "mean()", "X"  
The first code line is a function splitting strings at each "-" character.  
The second code line apply the splitting function for the feature names column, get the appropriate sliced part by anonymous function and stored it in a new column with corresponding name.

```{r}
# Creation of a function to avoid repetition
cutstrcol <- function(coltosplit){strsplit(coltosplit, "-")}
featurenames <- featurenames %>%
      mutate(feature = unlist(lapply(cutstrcol(measurementname), function(elt){elt[1]})), 
             estimate = unlist(lapply(cutstrcol(measurementname), function(elt){elt[2]})), 
             estimateparameter = unlist(lapply(cutstrcol(measurementname), function(elt){elt[3]})))
# Delete feature full name column
featurenames[,"measurementname"] <- NULL
```

Quick overview on the updated data set :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Sliced features names data set", dimensions = dim(featurenames), head = featurenames[1:2,])
```

### Combine subject ids, activity names and the measurements data

```{r}
fulldata <- cbind(combsubject, comblabels[,2], combfeature)
```

Quick overview on the updated data set :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Merged data set", dimensions = dim(fulldata), head_truncated.columns = fulldata[1:2,1:5])
```

### Make tidy data where each parsed features are split and set as a unique variable with corresponding value

The first code line make a tidy data with all the features labels (still are "V1" to "V561") and the measurements values.  
The second code line parse the features labels to set only the numeric piece as the name : "V1" => "1", "V2" => "2", etc ...

```{r}
fulldata <- fulldata %>% gather(key = measurement, value = value, -(subjectid:activity))
fulldata$measurement <- parse_number(fulldata$measurement)
```

Quick overview on the tidy data set :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Tidy data set", dimensions = dim(fulldata), head = fulldata[1:2,])
```

The next code block show the join of measurements tidy data set with complete and parsed features names.

```{r include=FALSE}
## Merge working dataset with features/measurements variables names
fulldata <- inner_join(fulldata, featurenames)
## Remove the intermediate "variable" col
fulldata[,"measurement"] <- NULL
## Reorder dataframe
fulldata <- fulldata[, c(1:2,4:6,3)]
```

Quick overview on the merged tidy data set :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Merged tidy data set", dimensions = dim(fulldata), head = fulldata[1:2,])
```

Finally, all data was loaded and merged to get a unique data set.  
The next step is to follow the last project instructions :  

* extract only the measurements on the mean and standard deviation for each measurement,
* create a second, independent tidy data set with the average of each variable for each activity and each subject.

## Subset some measurement features and summarize their average according to different variables

### Search from all features measurements the mean and standard deviation calculations

```{r}
extractdata <- fulldata[!is.na(fulldata$estimate) & (fulldata$estimate == "mean()" | fulldata$estimate == "std()"), ]
```

Then, group by all variables : 

```{r}
estimategrp <- extractdata %>% group_by(feature, estimateparameter, estimate, activity, subjectid)
```

Quick overview on the subsetted and grouped tidy data set :

```{r echo=FALSE, paged.print=FALSE}
list(name = "mean() and std() grouped tidy data set", dimensions = dim(estimategrp), head = estimategrp[1:2,])
```

Finally, summarize the average value of each feature for either each triaxial measurement or none triaxial specification, each activity and each subject id.  
And write the data in a text file.

```{r include=FALSE}
##  Tidy data set with the average of each variable for each activity and each subject
result <- estimategrp %>% summarize(mean(value))
## Export and write in a txt file the dataset
fwrite(x = result, file = "avgMeasures.txt", row.names = FALSE)
```
Even, if the output data can be seen in **avgMeasures.txt** text file, here's a quick overview :

```{r echo=FALSE, paged.print=FALSE}
list(name = "Summarize mean() and std() grouped tidy data set", dimensions = dim(result), head = result[1:2,])
```