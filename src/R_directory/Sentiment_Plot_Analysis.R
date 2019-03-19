setwd("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/src/R_directory")

# install and import sentiment plot library
install.packages("syuzhet")
install.packages("jsonlite")
install.packages("sqldf")
install.packages("hash")
library(hash)
library("syuzhet")
library(jsonlite)
library(sqldf)
library(plyr)
 
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

for (id in 1:length(unique_postIDs)){
  comments <- sqldf(paste("select clean_text from t where PostId=",as.character(id),""))
  
  # build sentiment plot
}


s_v <- get_sentences(my_example_text)

s_v_sentiment <- get_sentiment(s_v)

plot(
  s_v_sentiment, 
  type="l", 
  main="Example Plot Trajectory", 
  xlab = "Narrative Time", 
  ylab= "Emotional Valence"
)