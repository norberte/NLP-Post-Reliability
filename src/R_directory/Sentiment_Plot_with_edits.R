setwd("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/src/R_directory")

library("syuzhet")
library(jsonlite)
library(sqldf)
library(plyr)
library(ggplot2)
library(readr)

# importing JSON edits data
edits_df <- fromJSON(txt="../../data/clean_EditHistory_Of_Posts.json")
e <- edits_df$data

freq <- table(e$PostId)

# fix date formatting and re-order data
unique_postIDs_with_edits <- unique(e$PostId)
e$Edit_Date <- as.POSIXct(e$Edit_TimeStamp , format = "%Y-%m-%dT%H:%M:%OS" , tz = "GMT")
e$type <- "edit"
e_new <- e[order(e$PostId ,e$Edit_Date , decreasing = FALSE),]



# importing JSON comments data
comments_df <- fromJSON(txt="../../data/CleanComments.json")
t <- comments_df$data

# get a list of uniquePostIds, fix date formatting and re-order data
unique_postIDs <- unique(t$PostId)
t$DTime <- as.POSIXct(t$CreationDate , format = "%Y-%m-%dT%H:%M:%OS" , tz = "GMT")
t$type <- "comment"
t_new <- t[order(t$PostId ,t$DTime , decreasing = FALSE),]

# intersect the 2 different uniquePostIds lists to get the common post id's
postID_intersection <- intersect(unique_postIDs, unique_postIDs_with_edits)

sent_vecs <- vector(mode="list", length=length(postID_intersection))
commentsBetweenEdits <- vector(mode="list", length=length(postID_intersection))
totalScoreBetweenEdits <- vector(mode="list", length=length(postID_intersection))
cummulativeScores <- vector(mode="list", length=length(postID_intersection))
overall_sent_score <- vector(mode="numeric", length=length(postID_intersection))

for (index in 1:length(postID_intersection)){
  if(index %% 50 == 0) {
    print(index)
  }
  
  t_data <- sqldf(paste("select type, DTime, clean_text from t_new where PostId=", as.character(postID_intersection[index]),""))
  e_data <- sqldf(paste("select type, Edit_Date, clean_editComment from e_new where PostId=", as.character(postID_intersection[index]),""))
  
  merged_type <- data.frame(type = c(t_data$type, e_data$type))
  merged_text <- data.frame(text = c(t_data$clean_text, e_data$clean_editComment))
  merged_dates <- data.frame(date = c(t_data$DTime, e_data$Edit_Date))
  
  merged_data <- cbind(merged_type, merged_text, merged_dates)
  merged <- merged_data[order(merged_data$date, decreasing = FALSE),]
  
  # build sentiment plot
  sentiment <- get_sentiment(as.character(merged$text))
  sentiment_vector <- get_sentiment(as.character(merged$text), method="syuzhet")
  
  png(paste("comments_edits_sentiment_plots/SentPlot_postId_", as.character(postID_intersection[index]), ".png"))
  bool <- which(merged$type == "edit")
  comm <- which(merged$type == "comment")
   
  plot(
    sentiment, 
    type="b", 
    main= paste("Comments and Edits Sentiment Plot for PostId = ", as.character(postID_intersection[index]), ""), 
    xlab = "Comments and Edits", 
    ylab= "Emotional Valence"
  )
  abline(v = bool, col="red")
  points(x = bool, pch = 8, y = sentiment_vector[bool], col="red")
  points(x = comm, pch = 21, y = sentiment_vector[comm], col="black", bg ="blue")
  
  dev.off()
  sent_vecs[[index]] <- sentiment_vector
  overall_sent_score[[index]] <- sum(sentiment_vector)
  
  commentsBetween <- vector(mode="numeric", length=length(bool))
  totalScore <- vector(mode="numeric", length=length(bool))
  cummulative <- vector(mode="numeric", length=length(bool))
  
  for (num in 2:(length(bool)+1)){
    if(num == (length(bool)+1)){
      
      lastEdit_index = bool[num-1]
      lastIndex <- length(sentiment_vector)
      commentsBetween[num-1] = lastIndex - lastEdit_index
      
      startIndex <- (bool[num-1] + 1)
      endIndex <- length(sentiment_vector)
      if(startIndex > endIndex){ startIndex = endIndex }
      totalScore[num-1] = sum( sentiment_vector [ startIndex : endIndex ]  )
      
    } else {
      
      previousEdit_index = bool[num-1] 
      nextEdit_index <- bool[num]
      commentsBetween[num-1] = (nextEdit_index - previousEdit_index) - 1  # off by one, since you are not counting the edit itself
      
      startIndex <- bool[num-1] + 1
      endIndex <- bool[num]-1
      totalScore[num-1] = sum( sentiment_vector [ startIndex : endIndex ]  )
      
    }
    
    if(num == 2){
      cummulative[num-1] = totalScore[num-1] # current Score
    } else {
      cummulative[num-1] = cummulative[num-2] + totalScore[num-1] # previous + current Score
    }
  }
  
  commentsBetweenEdits[[index]] <- commentsBetween
  totalScoreBetweenEdits[[index]] <- totalScore
  cummulativeScores[[index]] <- cummulative
}


write("PostID, Overall_Sentiment_Score, Sentiment_Vector, Number_of_Comments_Between_Edits, Total_Scores_Between_Edits, Cummulative_Scores_Between_Edits", file="results.csv", append=T)
for(line in 1:length(sent_vecs)){
  x <- paste(postID_intersection[line], ", ", overall_sent_score[line]
             ,", \"[", paste(sent_vecs[[line]], collapse=','), "]\""
             ,", \"[", paste(commentsBetweenEdits[[line]], collapse=','), "]\""
             ,", \"[", paste(totalScoreBetweenEdits[[line]], collapse=','), "]\""
             ,", \"[", paste(cummulativeScores[[line]], collapse=','), "]\"") 
  write(x, file="results.csv", append=T)
}



analysis <- read_csv("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/src/R_directory/Analysis.csv", 
                     col_types = cols(EditCount = col_integer()))

analysis$PositivePercentage <- analysis$PositiveScore / (analysis$PositiveScore + analysis$NegativeScore) * 100
analysis$NegativePercentage <- analysis$NegativeScore / (analysis$PositiveScore + analysis$NegativeScore) * 100

analysis_df <- data.frame(editNumber = c(analysis$EditCount, analysis$EditCount), 
                         percentage = c(analysis$PositivePercentage, analysis$NegativePercentage), 
                         polarity = factor(c(rep("Positive", length = length(analysis$EditCount)), 
                                            rep("Negative", length = length(analysis$EditCount)) ), 
                                          levels=c("Positive","Negative")) )

analysis_df2 <- data.frame(editNumber = c(analysis$EditCount[1:100], analysis$EditCount[1:100]), 
                          percentage = c(analysis$PositivePercentage[1:100], analysis$NegativePercentage[1:100]),  
                          polarity = factor(c(rep("Positive", length = 100), 
                                              rep("Negative", length = 100) ), 
                                            levels=c("Positive","Negative")) )

analysis_df3 <- data.frame(editNumber = c(analysis$EditCount[1:50], analysis$EditCount[1:50]), 
                           percentage = c(analysis$PositivePercentage[1:50], analysis$NegativePercentage[1:50]), 
                           polarity = factor(c(rep("Positive", length = 50), 
                                               rep("Negative", length = 50) ), 
                                             levels=c("Positive","Negative")) )

analysis_df4 <- data.frame(editNumber = c(analysis$EditCount[1:35], analysis$EditCount[1:35]), 
                           percentage = c(analysis$PositivePercentage[1:35], analysis$NegativePercentage[1:35]), 
                           polarity = factor(c(rep("Positive", length = 35), 
                                               rep("Negative", length = 35) ), 
                                             levels=c("Positive","Negative")) )



ggplot(data = analysis_df, aes(fill=polarity, y=percentage, x=editNumber, label=round(percentage, 0))) + geom_bar(stat="identity") + 
  geom_text(size = 3, position = position_stack(vjust = 0.5)) + 
  labs(title = "Percentage of Overall Sentiment Polarity After Edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

ggplot(data = analysis_df, aes(x = editNumber, y = percentage, fill = polarity, label=round(percentage, 0))) + geom_bar(stat="identity", position=position_dodge()) +
  geom_text(size = 3, position=position_dodge(width=0.9), vjust=-0.25) + 
  labs(title = "Percentage of Overall Sentiment Polarity After Edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")


# A line graph
ggplot(data=analysis_df, aes(x=editNumber, y=percentage, group=polarity, colour=polarity, label=round(percentage, 0))) + 
  geom_line(aes(linetype=polarity), size=1) +     # Set linetype by polarity
  geom_text(size = 3, vjust=-0.75) + 
  geom_point(size=3, fill="white") +         # Use larger points, fill with white
  expand_limits(y=0) +                       # Set y range to include 0
  scale_colour_hue(name="Overall Sentiment Polarity",      # Set legend title
                   l=30)  +                  # Use darker colors (lightness=30)
  scale_shape_manual(name="Overall Sentiment Polarity",
                     values=c(22,21)) +      # Use points with a fill color
  scale_linetype_discrete(name="Overall Sentiment Polarity") +
  xlab("Number Of Edits") + ylab("Percentage Sentiment Polarity") + # Set axis labels
  ggtitle("Overall Sentiment Polarity After Edits on an Answer") +     # Set title
  theme_bw() +
  theme(legend.position=c(.7, .4))           # Position legend inside
# This must go after theme_bw



ggplot(data = analysis_df2, aes(fill=polarity, y=percentage, x=editNumber, label=round(percentage, 0))) + geom_bar(stat="identity") + 
  geom_text(size = 3, position = position_stack(vjust = 0.5)) + 
  labs(title = "Percentage of Sentiment Polarity On First 100 edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

ggplot(data = analysis_df2, aes(x = editNumber, y = percentage, fill = polarity, label=round(percentage, 0))) + geom_bar(stat="identity", position=position_dodge()) +
  geom_text(size = 3, position=position_dodge(width=0.9), vjust=-0.25) + 
  labs(title = "Percentage of Sentiment Polarity On First 100 edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

# A line graph
ggplot(data=analysis_df2, aes(x=editNumber, y=percentage, group=polarity, colour=polarity, label=round(percentage, 0))) + 
  geom_line(aes(linetype=polarity), size=1) +     # Set linetype by polarity
  geom_text(size = 3, vjust=-0.75) + 
  geom_point(size=3, fill="white") +         # Use larger points, fill with white
  expand_limits(y=0) +                       # Set y range to include 0
  scale_colour_hue(name="Overall Sentiment Polarity",      # Set legend title
                   l=30)  +                  # Use darker colors (lightness=30)
  scale_shape_manual(name="Overall Sentiment Polarity",
                     values=c(22,21)) +      # Use points with a fill color
  scale_linetype_discrete(name="Overall Sentiment Polarity") +
  xlab("Number Of Edits") + ylab("Percentage Sentiment Polarity") + # Set axis labels
  ggtitle("Sentiment Polarity Line Trend On First 100 edits on an Answer") +     # Set title
  theme_bw() +
  theme(legend.position=c(.7, .4))           # Position legend inside
# This must go after theme_bw




ggplot(data = analysis_df3, aes(fill=polarity, y=percentage, x=editNumber, label=round(percentage, 0))) + geom_bar(stat="identity") + 
  geom_text(size = 3, position = position_stack(vjust = 0.5)) + 
  labs(title = "Percentage of Sentiment Polarity On First 50 edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

ggplot(data = analysis_df3, aes(x = editNumber, y = percentage, fill = polarity, label=round(percentage, 0))) + geom_bar(stat="identity", position=position_dodge()) +
  geom_text(size = 3, position=position_dodge(width=0.9), vjust=-0.25) + 
  labs(title = "Percentage of Sentiment Polarity On First 50 edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

# A line graph
ggplot(data=analysis_df3, aes(x=editNumber, y=percentage, group=polarity, colour=polarity, label=round(percentage, 0))) + 
  geom_line(aes(linetype=polarity), size=1) +     # Set linetype by polarity
  geom_text(size = 3, vjust=-0.75) + 
  geom_point(size=3, fill="white") +         # Use larger points, fill with white
  expand_limits(y=0) +                       # Set y range to include 0
  scale_colour_hue(name="Overall Sentiment Polarity",      # Set legend title
                   l=30)  +                  # Use darker colors (lightness=30)
  scale_shape_manual(name="Overall Sentiment Polarity",
                     values=c(22,21)) +      # Use points with a fill color
  scale_linetype_discrete(name="Overall Sentiment Polarity") +
  xlab("Number Of Edits") + ylab("Percentage Sentiment Polarity") + # Set axis labels
  ggtitle("Sentiment Polarity Line Trend On First 50 edits on an Answer") +     # Set title
  theme_bw() +
  theme(legend.position=c(.7, .4))           # Position legend inside
# This must go after theme_bw




ggplot(data = analysis_df4, aes(fill=polarity, y=percentage, x=editNumber, label=round(percentage, 0))) + geom_bar(stat="identity") + 
  geom_text(size = 3, position = position_stack(vjust = 0.5)) + 
  labs(title = "Percentage of Sentiment Polarity On First 20 edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

ggplot(data = analysis_df4, aes(x = editNumber, y = percentage, fill = polarity, label=round(percentage, 0))) + geom_bar(stat="identity", position=position_dodge()) +
  geom_text(size = 3, position=position_dodge(width=0.9), vjust=-0.25) + 
  labs(title = "Percentage of Sentiment Polarity On First 20 edits on an Answer", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

# A line graph
ggplot(data=analysis_df4, aes(x=editNumber, y=percentage, group=polarity, colour=polarity, label=round(percentage, 0))) + 
  geom_line(aes(linetype=polarity), size=1) +     # Set linetype by polarity
  geom_text(size = 3, vjust=-0.75) + 
  geom_point(size=3, fill="white") +         # Use larger points, fill with white
  expand_limits(y=0) +                       # Set y range to include 0
  scale_colour_hue(name="Overall Sentiment Polarity",      # Set legend title
                   l=30)  +                  # Use darker colors (lightness=30)
  scale_shape_manual(name="Overall Sentiment Polarity",
                     values=c(22,21)) +      # Use points with a fill color
  scale_linetype_discrete(name="Overall Sentiment Polarity") +
  xlab("Number Of Edits") + ylab("Percentage Sentiment Polarity") + # Set axis labels
  ggtitle("Sentiment Polarity Line Trend On First 20 edits on an Answer") +     # Set title
  theme_bw() +
  theme(legend.position=c(.7, .4))           # Position legend inside
# This must go after theme_bw




numberOfEdits <- vector(mode="numeric", length=length(postID_intersection))
numberOfComm <-  vector(mode="numeric", length=length(postID_intersection))

for (index in 1:length(postID_intersection)){
  if(index %% 50 == 0) {
    print(index)
  }
  
  t_data <- sqldf(paste("select type, DTime, clean_text from t_new where PostId=", as.character(postID_intersection[index]),""))
  e_data <- sqldf(paste("select type, Edit_Date, clean_editComment from e_new where PostId=", as.character(postID_intersection[index]),""))
  
  merged_type <- data.frame(type = c(t_data$type, e_data$type))
  merged_text <- data.frame(text = c(t_data$clean_text, e_data$clean_editComment))
  merged_dates <- data.frame(date = c(t_data$DTime, e_data$Edit_Date))
  
  merged_data <- cbind(merged_type, merged_text, merged_dates)
  merged <- merged_data[order(merged_data$date, decreasing = FALSE),]
  
  bool <- which(merged$type == "edit")
  comm <- which(merged$type == "comment")
  
  numberOfComm[[index]] <- length(comm)
  numberOfEdits[[index]] <- length(bool)
}



plot(x = analysis$EditCount, y = (analysis$NegativeScore + analysis$PositiveScore), type="l",
     main="Evolution of Stack Overflow posts: Number of Posts vs. Number of Edits graph", 
     sub="How often are Stack Overflow posts edited ?", xlab = "Number of Edits", ylab = "Number of Posts")

plot(x = analysis$EditCount[1:100], y = (analysis$NegativeScore[1:100] + analysis$PositiveScore[1:100]), type="l",
     main="Evolution of Stack Overflow posts: First 100 edits", 
     sub="How often are Stack Overflow posts edited ?", xlab = "Number of Edits", ylab = "Number of Posts")

plot(x = analysis$EditCount[1:50], y = (analysis$NegativeScore[1:50] + analysis$PositiveScore[1:50]), type="l",
     main="Evolution of Stack Overflow posts: First 50 edits", 
     sub="How often are Stack Overflow posts edited ?", xlab = "Number of Edits", ylab = "Number of Posts")

plot(x = analysis$EditCount[1:20], y = (analysis$NegativeScore[1:20] + analysis$PositiveScore[1:20]), type="l",
     main="Evolution of Stack Overflow posts: First 20 edits", 
     sub="How often are Stack Overflow posts edited ?", xlab = "Number of Edits", ylab = "Number of Posts")

#-- sandbox -------------------------------------------------------

#paste(postID_intersection[line], ", ", overall_sent_score[line]
#      ,", \"[", paste(sent_vecs[[line]], collapse=','), "]\""
#      ,", \"[", paste(commentsBetweenEdits[[line]], collapse=','), "]\""
#      ,", \"[", paste(totalScoreBetweenEdits[[line]], collapse=','), "]\""
#      ,", \"[", paste(cummulativeScores[[line]], collapse=','), "]\"") 

#library(data.table)
#data <- fread(file="results.csv")

