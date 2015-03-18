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
#If you don't have these, you need to install them using the following syntax example (rpart is included)
#install.packages('RColorBrewer')

#Create a table to show you how many people survived (1) and perished (0)
#table(train$Survived)

#Create a proportion table to show you percentages of the above
#prop.table(table(train$Survived))

#Create a summary table based on a field.  This shows you how many males and how many femails
#summary(train$Sex)

#Create a proportion table based on multiple factors.  In this case, a breakdown of man versus women_
#and their survial rate.  The "1" at the end ensures percents are borken down against the sex grouping_
#and not the enitre dataset
#prop.table(table(train$Sex, train$Survived),1)

#Lets do some analytics on Children.
#First create a column to indicate if they are children and set the value to false
#train$Child <- 0
#Now lets set that that to true for all persons below the age of 18
#train$Child[train$Age < 18] <- 1
#Running a proportion table on Children Survival Rate should show about a 50/50 shot.
#prop.table(table(train$Child, train$Survived), 1)

#To get a count of survival based on multip categories you create an aggregate
#The field to the left of the tilda (~) is what you are looking for, the fields on the right what you_
#are comparing to it.  Follow then by the data set you are looking at and the function.  
#Sum will get you the counts that meet that critia.  Lenght will get you the total count in the categories
#The code following will show you how many men and women broken down into adult/child survived.
#aggregate(Survived ~ Child + Sex, data=train, FUN=sum)
#Next, changing the FUN to Lenght will get you the total count in the categories
#aggregate(Survived ~ Child + Sex, data=train, FUN=length)
#To combine these two sets of data and get percentages similar to a prop table do this:
#aggregate(Survived ~ Child + Sex, data=train, FUN=function(x) {sum(x)/length(x)})

#Now we'll take a look at the fare class.  Lets create a new field (Fare2) that will break down the fare_
#into one of three categories
#train$Fare2 <- '30+'
#train$Fare2[train$Fare < 30 & train$Fare >= 20] <- '20-30'
#train$Fare2[train$Fare < 20 & train$Fare >= 10] <- '10-20'
#train$Fare2[train$Fare < 10] <- '<10'

#Now lets analyze this field, along with class and the previous field sex
#aggregate(Survived ~ Fare2 + Pclass + Sex, data=train, FUN=function(x) {sum(x)/length(x)})
#You should see that a small group of ladies were less likely to surive, the 20-30 and 30+ of class 3
#To update our test set based on this new found knowledge we would do this:
#test$Survived <- 0
#test$Survived[test$Sex == 'female'] <- 1
#test$Survived[test$Sex == 'female' & test$Pclass == 3 & test$Fare >= 20] <- 0


#Create a survived column in the test dataset and set all values to 0
#test$Survived <- rep(0, 418)
#Or
#test$Survived <- 0
#Now lets say that all the women survived
#test$Survived[test$Sex == 'female'] <- 1


#Decision Trees using rpart
#Similar to aggregate, the field you caculating on to the left of the tilda, and the fields to compare_
#on the right, followed by the data set, then the method
#fit <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, data=train, method="class")
#If you want to adjust how complex the decsion tree can get, you can add a control to the end of it_
#The two settings for this are minsplit and cp(comlexity)
#fit <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, data=train, method="class", control=rpart.control(minsplit=2, cp=0))

#Now you can create some visuals using what you just created
#fancyRpartPlot(fit)

#If you want to create an interactive tree of plots where you can X out some trees do this:
#new.fit <- prp(fit,snip=TRUE)$obj
#fancyRpartPlot(new.fit)
#When you are done X'ing them out, TYpe "Quit"  

#After analyzing the data, lets create a prediction based on the decision tree (fit) that we just created
#Prediction <- predict(fit, test, type = "class")
#Above we have a new "variable" called Prediction which is creating a prediction "predict" based on the_
#datatree "fit", applying it to the data set "test", with a type of "class" (for 1's and 0's)


#Combing Data Sets : Each data set must have the same fields.
#So if starting from scrath, create a Survived Colum in test
  #test$Survived <- NA
#Now to get down to business. 
  #combi <- rbind(train, test)
#This creates a new dataset called combi

#Split up the Name so that we can grab the title
#The following usesstrsplit, followed by the dataset$field, what to split on (comma and period), then_
#the array type stuff.  1 gets the name, 2 gets the 2nd of three separations, or 2nd value of the array
#strsplit(combi$Name[1], split='[,.]')[[1]][2]

#To apply the above to all objects or records of the dataset
#combi$Title <- sapply(combi$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][2]})

#The above work actually leaves a space in front of the title. That can be removed by subsituting
#Here we substitute the space with nothing
#combi$Title <- sub(' ', '', combi$Title)

#Now lets combine some like values
#combi$Title[combi$Title %in% c('Mme', 'Mlle')] <- 'Mlle'
#combi$Title[combi$Title %in% c('Capt', 'Don', 'Major', 'Sir')] <- 'Sir'
#combi$Title[combi$Title %in% c('Dona', 'Lady', 'the Countess', 'Jonkheer')] <- 'Lady'

#Now we need to confer the field Title back to a factor.  As you recall, it was changed to a string earlier
#combi$Title <- factor(combi$Title)

#Lets create a field called family size and use a few existing fields plus the person in question
#combi$FamilySize <- combi$SibSp + combi$Parch + 1

#Now we will create a new field Surname that we will yank from the name field using string splitting
#combi$Surname <- sapply(combi$Name, FUN=function(x) {strsplit(x, split='[,.]')[[1]][1]})

#Lets also create a new field that will combine family size and surname.  Looking for large families
#combi$FamilyID <- paste(as.character(combi$FamilySize), combi$Surname, sep="")
#Result should like like 3Barb
#If the family is less then 3 people, lets just classify it as small in the FamilyID field
#combi$FamilyID[combi$FamilySize <= 2] <- 'Small'
#Now we'll creat a dataset will just the FamilyIDs to work with
#famIDs <- data.frame(table(combi$FamilyID))
#Filter it down to only show those less then or equal to 2
#famIDs <- famIDs[famIDs$Freq <= 2,]
#Now we can update the main dataset (combi) and update those families as 'Small'
#combi$FamilyID[combi$FamilyID %in% famIDs$Var1] <- 'Small'
#combi$FamilyID <- factor(combi$FamilyID)

#Finally we'll split combi data back into the orginal datasets
#rain <- combi[1:891,]
#test <- combi[892:1309,]

#Lets rpart this stuff
#fit <- rpart(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked + Title + FamilySize + FamilyID, data=train, method="class")
#Make a prediction
##Prediction <- predict(fit, test, type = "class")




#Create a dataframe with the necessary data for the Kaggle Submission (PassengerID & Survived)
submit <- data.frame(PassengerId = test$PassengerId, Survived = test$Survived)
#Create a CSV from the dataset we just created with a name and no row names
write.csv(submit, file = "theyallperish.csv", row.names = FALSE)