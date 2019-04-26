setwd("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/src/R_directory")

library("syuzhet")
library(jsonlite)
library(sqldf)
library(plyr)
library(ggplot2)
library(readr)
library(stringr)

# importing tags data
PostTags <- read_csv("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/data/PostTags.csv")

PostTags$LastEditDate <- as.POSIXct(PostTags$LastEditDate, format = "%Y-%m-%d %H:%M:%OS" , tz = "GMT")
PostTags$LastActivityDate <- as.POSIXct(PostTags$LastActivityDate, format = "%Y-%m-%d %H:%M:%OS" , tz = "GMT")

library(gsubfn)
PostTags$cleanTags <- lapply(PostTags$Tags, function(x){strapplyc(x, "<(.*?)>", simplify = c)})


tags <- unlist(PostTags$cleanTags)

filtered_sorted_freq_table <- sort(table(tags)[table(tags) > 11])

prob_table <- prop.table(sorted_freq_table)
filtered_sorted_prob_table <- sort(prob_table[prop.table(sorted_freq_table) > 0.005])



tags <- c(".net", "dom", "json", "objective-c" , "angularjs", "url", "c", "bash", "regex","arrays", "c#", "swift", "css","java", "php", "ios", "string", "html", "c++", "jquery", "python", "android", "git", "javascript")
percentage <- as.numeric(filtered_sorted_prob_table) * 100
freq <- as.numeric(filtered_sorted_freq_table)

freq_df <- data.frame(topTags = tags, frequency= freq)
percentage_df <- data.frame(topTags = tags, percent = percentage)


ggplot(data=freq_df, aes(x=topTags, y=freq)) + geom_bar(stat = "identity") + coord_flip() + 
  labs(title = "Tag Distribution of Most Frequent Tags on Posts", y = "Frequency of Tag", x = "Tag Name")

ggplot(data=percentage_df, aes(x=topTags, y=percent)) + geom_bar(stat = "identity") + coord_flip() + 
  labs(title = "Tag Distribution of Most Frequent Tags on Posts", y = "Percentage of Tag from Overall", x = "Frequency of Tag")


# top 5 most frequent tags
tail(filtered_sorted_prob_table, 5) # jquery, python, android, git, javascript

# 3 less frequent tags
head(filtered_sorted_prob_table, 15)   # choose 3: c, html, c++




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


# Posts with jQuery sentiment tag analysis-----
tags_to_be_analyzed <- c("jquery", "python", "android", "git", "javascript", "c", "html", "c#")


for (index in 1:length(tags_to_be_analyzed)){
  print(paste("Analyzing posts with tag: ", tags_to_be_analyzed[index]))
  tag_sentiment_trend_analysis(tags_to_be_analyzed[index])
}







tag_sentiment_trend_analysis <- function(tag){
  str <- str_replace_all(string=paste("<",as.character(tag), ">"), pattern=" ", repl="")
  isSubstring <- lapply(PostTags$Tags, function(x){grepl(str, x)})
  indeces <- which(isSubstring == TRUE)
  postIDs <- PostTags$PostId[indeces]
  
  
  sent_vecs <- vector(mode="list", length=length(postIDs))
  commentsBetweenEdits <- vector(mode="list", length=length(postIDs))
  totalScoreBetweenEdits <- vector(mode="list", length=length(postIDs))
  cummulativeScores <- vector(mode="list", length=length(postIDs))
  overall_sent_score <- vector(mode="numeric", length=length(postIDs))
  
  for (index in 1:length(postIDs)){
    t_data <- sqldf(paste("select type, DTime, clean_text from t_new where PostId=", as.character(postIDs[index]),""))
    e_data <- sqldf(paste("select type, Edit_Date, clean_editComment from e_new where PostId=", as.character(postIDs[index]),""))
    
    merged_type <- data.frame(type = c(t_data$type, e_data$type))
    merged_text <- data.frame(text = c(t_data$clean_text, e_data$clean_editComment))
    merged_dates <- data.frame(date = c(t_data$DTime, e_data$Edit_Date))
    
    merged_data <- cbind(merged_type, merged_text, merged_dates)
    merged <- merged_data[order(merged_data$date, decreasing = FALSE),]
    
    # build sentiment plot
    sentiment <- get_sentiment(as.character(merged$text))
    sentiment_vector <- get_sentiment(as.character(merged$text), method="syuzhet")
    
    #png(paste(as.character(tag),"_sentiment_plots/SentPlot_postId_", as.character(postIDs[index]), ".png"))
    bool <- which(merged$type == "edit")
    comm <- which(merged$type == "comment")
    
    plot(
      sentiment, 
      type="b", 
      main= paste("Sentiment Plot for PostId = ", as.character(postIDs[index]), " with tag ", as.character(tag) ), 
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
  print(paste("For ", as.character(tag), "tag the avg sentiment score is: ", as.character(mean(overall_sent_score))))
  print("Summary for overall sent scores:")
  print(summary(overall_sent_score))
  print("\n")
  
  write("PostID, Overall_Sentiment_Score, Sentiment_Vector, Number_of_Comments_Between_Edits, Total_Scores_Between_Edits, Cummulative_Scores_Between_Edits", file=paste("sentiment tag trend results/", as.character(tag), "_tag_sentiment_trend_analysis_results.csv"), append=T)
  for(line in 1:length(sent_vecs)){
    x <- paste(postID_intersection[line], ", ", overall_sent_score[line]
               ,", \"[", paste(sent_vecs[[line]], collapse=','), "]\""
                ,", \"[", paste(commentsBetweenEdits[[line]], collapse=','), "]\""
               ,", \"[", paste(totalScoreBetweenEdits[[line]], collapse=','), "]\""
               ,", \"[", paste(cummulativeScores[[line]], collapse=','), "]\"") 
    write(x, file=paste("sentiment tag trend results/", as.character(tag), "_tag_sentiment_trend_analysis_results.csv"), append=T)
  }
}


