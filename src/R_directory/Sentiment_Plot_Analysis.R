setwd("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/src/R_directory")

# install and import sentiment plot library
install.packages("syuzhet")
install.packages("jsonlite")
install.packages("sqldf")

library("syuzhet")
library(jsonlite)
library(sqldf)
library(plyr)

if (!require("pacman")) install.packages("pacman")
library(pacman)
pacman::p_load(tidyverse, magrittr, ggstance, textshape, gridExtra, viridis, quanteda, textreadr)
pacman::p_load_current_gh('trinker/gofastr')
pacman::p_load_gh("trinker/textshape")
library(textshape)
 
# importing XML data
#library(XML)
#xmlfile <- xmlTreeParse("C:/Users/Norbert/Desktop/NLP/NLP_project_R_dir/TestFileBackUp.xml")
#topxml <- xmlRoot(xmlfile)
#topxml <- xmlSApply(topxml, function(x) xmlSApply(x, xmlValue))
#xml_df <- data.frame(t(topxml), row.names=NULL)

# importing JSON data
comments_df <- fromJSON(txt="../../data/CleanComments.json")

# take a look at the data
head(comments_df$data)

# all the data in a separate table
t <- comments_df$data
# all unique post IDs
unique_postIDs <- unique(t$PostId)

# get comments for each post

for (id in 10000:15000){
  comments <- sqldf(paste("select clean_text from t where PostId=",as.character(unique_postIDs[id]),""))
  
  if(id %% 500 == 0) {
    print(id)
  }
  #1. build sentiment plot
  s_v_sentiment <- get_sentiment(comments$clean_text)
  syuzhet_vector <- get_sentiment(comments$clean_text, method="syuzhet")
  
  #png(paste("sentiment_plots/SentPlot_postId_", as.character(unique_postIDs[id]), ".png"))
  
  #plot(
  #  s_v_sentiment, 
  #  type="l", 
  #  main= paste("Comments Sentiment Plot for PostId = ", as.character(unique_postIDs[id])), 
  #  xlab = "Comments", 
  #  ylab= "Emotional Valence"
  #)
  #dev.off()
  

  if(length(syuzhet_vector) > 5 && length(syuzhet_vector) < 40){
    #3. build sentiment Transformed Values plot
    dct_values <- get_dct_transform(syuzhet_vector, low_pass_size = 5)
    
    png(paste("sentiment_plots/SentPlot_postId_", as.character(unique_postIDs[id]), "_Transformed_Values.png"))
    plot(
      dct_values, 
      type ="l", 
      main=paste("Sentiment Plot Using Transformed Values for PostId = ", as.character(unique_postIDs[id])), 
      xlab =  "Comments", 
      ylab = "Emotional Valence", 
      col = "red",
      ylim=c(.1,.1)
    )
    dev.off()
    
    
    #4. build sentiment simple plot
    #png(paste("sentiment_plots/SentPlot_postId_", as.character(unique_postIDs[id]), "_SimplePlot.png"))
    #simple_plot(s_v_sentiment)
    #dev.off()
    
    #2. build sentiment percentage value plot
    if (length(syuzhet_vector) > 20){
      percent_vals <- get_percentage_values(syuzhet_vector, bins = 10)
      
      png(paste("sentiment_plots/SentPlot_postId_", as.character(unique_postIDs[id]), "_PercentageBasedMeans.png"))
      plot(
        percent_vals, 
        type="l", 
        main=paste("Sentiment Plot Using Percentage-Based Means for PostId = ", as.character(unique_postIDs[id])), 
        xlab =  "Comments", 
        ylab= "Emotional Valence", 
        col="red",
        ylim=c(0.1,.1)
      )
      dev.off()
    } else if (length(syuzhet_vector) > 10){
      percent_vals <- get_percentage_values(syuzhet_vector, bins = 5)
      
      png(paste("sentiment_plots/SentPlot_postId_", as.character(unique_postIDs[id]), "_PercentageBasedMeans.png"))
      plot(
        percent_vals, 
        type="l", 
        main=paste("Sentiment Plot Using Percentage-Based Means for PostId = ", as.character(unique_postIDs[id])), 
        xlab =  "Comments", 
        ylab= "Emotional Valence", 
        col="red",
        ylim=c(0.1,.1)
      )
      dev.off()
    }
    
    #5. get NRC emotion lexicon data
    nrc_data <- get_nrc_sentiment(comments$clean_text)
    
    png(paste("sentiment_plots/SentPlot_postId_", as.character(unique_postIDs[id]), "_EmotionDetection.png"))
    barplot(
      sort(colSums(prop.table(nrc_data[, 1:8]))), 
      horiz = TRUE, 
      cex.names = 0.7, 
      las = 1, 
      main = paste("Emotions in PostId = ", as.character(unique_postIDs[id]), xlab="Percentage"),
      ylim=c(0.1,.1)
    )
    dev.off()
  }
}
 


####### code not working ---------------------
#4. build sentiment simple plot
png(paste("sentiment_plots/SentPlot_postId_", as.character(unique_postIDs[id]), "_SimplePlot.png"))
simple_plot(s_v_sentiment)
dev.off()


