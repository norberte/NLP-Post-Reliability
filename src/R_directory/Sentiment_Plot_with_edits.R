setwd("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/src/R_directory")

library("syuzhet")
library(jsonlite)
library(sqldf)
library(plyr)

# importing JSON edits data
edits_df <- fromJSON(txt="../../data/clean_EditHistory_Of_Posts.json")
e <- edits_df$data

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









#-- sandbox -------------------------------------------------------

t_data <- sqldf("select type, clean_text, DTime from t_new where PostId=3071")
e_data <- sqldf("select type, clean_editComment, Edit_Date from e_new where PostId=3071")

merged_type <- data.frame(type = c(t_data$type, e_data$type))
merged_text <- data.frame(text = c(t_data$clean_text, e_data$clean_editComment))
merged_dates <- data.frame(date = c(t_data$DTime, e_data$Edit_Date))

merged_data <- cbind(merged_type, merged_text, merged_dates)
merged <- merged_data[order(merged_data$date, decreasing = FALSE),]

# build sentiment plot
sentiment <- get_sentiment(as.character(merged$text))
sentiment_vector <- get_sentiment(as.character(merged$text), method="syuzhet")

bool <- which(merged$type == "edit")
comm <- which(merged$type == "comment")

sent_vecs <- sentiment_vector
overall_sent_score <- sum(sentiment_vector)
commentsBetweenEdits <- vector(mode="numeric", length=length(bool))
totalScoreBetweenEdits <- vector(mode="numeric", length=length(bool))
cummulativeScores <- vector(mode="numeric", length=length(bool))

for (num in 2:(length(bool)+1)){
  if(num == (length(bool)+1)){
    
    lastEdit_index = bool[num-1]
    lastIndex <- length(sentiment_vector)
    commentsBetweenEdits[num-1] = lastIndex - lastEdit_index
    
    startIndex <- (bool[num-1] + 1)
    endIndex <- length(sentiment_vector)
    totalScoreBetweenEdits[num-1] = sum( sentiment_vector [ startIndex : endIndex ]  )
    
  } else {
    
    previousEdit_index = bool[num-1] 
    nextEdit_index <- bool[num]
    commentsBetweenEdits[num-1] = (nextEdit_index - previousEdit_index) - 1  # off by one, since you are not counting the edit itself
    
    startIndex <- bool[num-1] + 1
    endIndex <- bool[num]-1
    
    totalScoreBetweenEdits[num-1] = sum( sentiment_vector [ startIndex : endIndex ]  )
  }
  
  if(num == 2){
    cummulativeScores[num-1] = totalScoreBetweenEdits[num-1] # current Score
  } else {
    cummulativeScores[num-1] = cummulativeScores[num-2] + totalScoreBetweenEdits[num-1] # previous + current Score
  }
}



#paste(postID_intersection[line], ", ", overall_sent_score[line]
#      ,", \"[", paste(sent_vecs[[line]], collapse=','), "]\""
#      ,", \"[", paste(commentsBetweenEdits[[line]], collapse=','), "]\""
#      ,", \"[", paste(totalScoreBetweenEdits[[line]], collapse=','), "]\""
#      ,", \"[", paste(cummulativeScores[[line]], collapse=','), "]\"") 

#library(data.table)
#data <- fread(file="results.csv")

