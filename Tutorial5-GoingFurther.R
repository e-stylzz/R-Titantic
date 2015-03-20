#Author: Eric Barb
#Description:  Working through the tutorials of Trevor Stephens
#Section: Tutorial 5

#Set the working directory
setwd("~/GitHub/R-Titantic")

#Import the data sets
train <- read.csv("~/GitHub/R-Titantic/train.csv")
test <- read.csv("~/GitHub/R-Titantic/test.csv")

#Alternate Import that brings text in as strings
#train <- read.csv("~/GitHub/R-Titantic/train.csv", stringsAsFactors=FALSE)
#test <- read.csv("~/GitHub/R-Titantic/test.csv", stringsAsFactors=FALSE)

#Bring in our libraries
library(rpart)
library(rattle)
library(rpart.plot)
library(RColorBrewer)
library(randomForest)
library(party)
#If you don't have these, you need to install them using the following syntax example (rpart is included)
#install.packages('RColorBrewer')


#####DATA PREPERATION#####

#Create a Survived Column in Test so that we can combine the datasets
test$Survived <- NA
combi <- rbind(train, test)

#Create FamilySize Variable
combi$FamilySize <- combi$SibSp + combi$Parch + 1

#Convert Name to String to do some splitting
combi$Name <- as.character(combi$Name)
#Create Title Variable by Splittng Name
combi$Title <- sapply(combi$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][2]})
combi$Title <- sub(' ', '', combi$Title)
combi$Title[combi$Title %in% c('Mme', 'Mlle')] <- 'Mlle'
combi$Title[combi$Title %in% c('Capt', 'Don', 'Major', 'Sir')] <- 'Sir'
combi$Title[combi$Title %in% c('Dona', 'Lady', 'the Countess', 'Jonkheer')] <- 'Lady'
combi$Title <- factor(combi$Title)

#Create a Last Name field by pulling it out of the name field.  Split on ,'s and .'s and then take the first array value
combi$Surname <- sapply(combi$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][1]})

#now we will create a family id based on size and surname (lastname)
combi$FamilyID <- paste(as.character(combi$FamilySize), combi$Surname, sep="")
#If family size is 2 or less, just make the family id = to small
combi$FamilyID[combi$FamilySize <= 2] <- 'Small'
combi$FamilyID <- factor(combi$FamilyID)

#Random Forests can only digest factors up to 32 levels.  FOr this approach, we are going to modify the FamilyID a bit to make it smaller.
#Create a new variable to work iwth :  FamilyID2
combi$FamilyID2 <- combi$FamilyID
#Convert it to string to work with
combi$FamilyID2 <- as.character(combi$FamilyID2)
#Classify it as small if the family size is 3 or less as opposed to 2 or less.
combi$FamilyID2[combi$FamilySize <= 3] <- 'Small'
#Convert it back to a factor for analysis
combi$FamilyID2 <- factor(combi$FamilyID2)



#New Shit New Shit
#Convert Cabin to character so that we can split that up into a new column
combi$Cabin <- as.character(combi$Cabin)
combi$Cabin2 <- sapply(combi$Cabin, FUN=function(x) {strsplit(x, split='[ ]')[[1]][1]})
#Clean up weird entires where cabin looks like "F G73" for example
combi$Cabin2[c(76, 716)] = "G73"    #: which(combi$Cabin == 'F G73')
combi$Cabin2[c(129)] = "E69"        #: which(combi$Cabin == 'F E69')
combi$Cabin2[c(700, 949)] = "G63"        #: which(combi$Cabin == 'F G63')
#Change Cabin back to a facor
combi$Cabin <- factor(combi$Cabin)
#Convert new variable to string
combi$Cabin2  <- as.character(combi$Cabin2)
#Split Cabin 2 taking the first character and putting it into Deck and taking the number and putting it into Location
combi$Deck <- sapply(combi$Cabin2, FUN=function(x) {strsplit(x, split='[[:digit:]]')[[1]][1]})
combi$Location <- sapply(combi$Cabin2, FUN=function(x) {strsplit(x, split='[[:alpha:]]')[[1]][2]})
#Convert stuff back to factors
combi$Cabin2  <- factor(combi$Cabin2)
combi$Deck  <- factor(combi$Deck)
combi$Location  <- factor(combi$Location)




#####DATA CLEANSING######

#Guestimate the age using rpart for all objects that don't have NA for the age, and then apply that to all records with NA for the age
Agefit <- rpart(Age ~ Pclass + Sex + SibSp + Parch + Fare + Embarked + Title + FamilySize, data=combi[!is.na(combi$Age),], method="anova")
combi$Age[is.na(combi$Age)] <- predict(Agefit, combi[is.na(combi$Age),])

#Going through the tutorial we know that we are missing data for two employees for the embarked variable.  
#To find out which 2, run:  which(combi$Embarked == '') : this results in 62 & 830
#Lets set both of those to be 'S' since so many folks embarked from South Hampton then convert it back to a factor
combi$Embarked[c(62,830)] = "S"
combi$Embarked <- factor(combi$Embarked)

#Going through the tutorial we know that one person was missing a Fare, so we have figured out that person id is 1044 and we'll replace that
#with the median fare of our data
combi$Fare[1044] <- median(combi$Fare, na.rm=TRUE)


#####OTHER STUFF#####

#Lets split up combi back into our original datasets
train <- combi[1:891,]
test <- combi[892:1309,]

#Set the seed so that while working with randomized data, your tests always key off the same starting point for consistent results
set.seed(666)

#Time to run the model
###fit <- randomForest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamilySize + FamilyID2, data=train, importance=TRUE, ntree=2000)
#OR us a conditional inference tree
fit <- cforest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamilySize + FamilyID, data = train, controls=cforest_unbiased(ntree=2000, mtry=3))

#Plot the results
varImpPlot(fit)

#Time to crete a prediciton and apply it to the test data
###Prediction <- predict(fit, test)
#OR if using a condial inference tree
Prediction <- predict(fit, test, OOB=TRUE, type = "response")

#Create a dataframe with the necessary data for the Kaggle Submission (PassengerID & Survived)
submit <- data.frame(PassengerId = test$PassengerId, Survived = Prediction)
#Create a CSV from the dataset we just created with a name and no row names
write.csv(submit, file = "randomforestresults.csv", row.names = FALSE)

