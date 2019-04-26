library(plyr)
library(ggplot2)
library(readr)


analysis <- read_csv("C:/Users/Norbert/PycharmProjects/NLP-Post-Reliability/src/R_directory/analysis files/python _tag_sentiment_trend_Analysis.csv", 
                                                 col_names = FALSE, 
                                                 col_types = cols(X1 = col_integer(), X2 = col_integer(), X3 = col_integer()))
colnames(analysis) <- c("EditCount","PositiveScore","NegativeScore")



analysis$PositivePercentage <- analysis$PositiveScore / (analysis$PositiveScore + analysis$NegativeScore) * 100
analysis$NegativePercentage <- analysis$NegativeScore / (analysis$PositiveScore + analysis$NegativeScore) * 100

analysis_df <- data.frame(editNumber = c(analysis$EditCount, analysis$EditCount), 
                          percentage = c(analysis$PositivePercentage, analysis$NegativePercentage), 
                          polarity = factor(c(rep("Positive", length = length(analysis$EditCount)), 
                                              rep("Negative", length = length(analysis$EditCount)) ), 
                                            levels=c("Positive","Negative")) )


analysis_df4 <- data.frame(editNumber = c(analysis$EditCount[1:20], analysis$EditCount[1:20]), 
                           percentage = c(analysis$PositivePercentage[1:20], analysis$NegativePercentage[1:20]), 
                           polarity = factor(c(rep("Positive", length = 20), 
                                               rep("Negative", length = 20) ), 
                                             levels=c("Positive","Negative")) )



ggplot(data = analysis_df, aes(fill=polarity, y=percentage, x=editNumber, label=round(percentage, 0))) + geom_bar(stat="identity") + 
  geom_text(size = 3, position = position_stack(vjust = 0.5)) + 
  labs(title = "Percentage of Overall Sentiment Polarity On Posts with python tag", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

ggplot(data = analysis_df, aes(x = editNumber, y = percentage, fill = polarity, label=round(percentage, 0))) + geom_bar(stat="identity", position=position_dodge()) +
  geom_text(size = 3, position=position_dodge(width=0.9), vjust=-0.25) + 
  labs(title = "Percentage of Overall Sentiment Polarity On Posts with python tag", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")


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
  ggtitle("Percentage of Overall Sentiment Polarity On Posts with python tag") +     # Set title
  theme_bw() +
  theme(legend.position=c(.7, .4))           # Position legend inside
# This must go after theme_bw




ggplot(data = analysis_df4, aes(fill=polarity, y=percentage, x=editNumber, label=round(percentage, 0))) + geom_bar(stat="identity") + 
  geom_text(size = 3, position = position_stack(vjust = 0.5)) + 
  labs(title = "Percentage of Overall Sentiment Polarity On Posts w/ python tag: First 20 edits", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

ggplot(data = analysis_df4, aes(x = editNumber, y = percentage, fill = polarity, label=round(percentage, 0))) + geom_bar(stat="identity", position=position_dodge()) +
  geom_text(size = 3, position=position_dodge(width=0.9), vjust=-0.25) + 
  labs(title = "Percentage of Overall Sentiment Polarity On Posts w/ python tag: First 20 edits", y = "Percentage Sentiment Polarity", x = "Number Of Edits", fill = "Overall Sentiment Polarity")

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
  ggtitle("Percentage of Overall Sentiment Polarity On Posts w/ python tag: First 20 edits") +     # Set title
  theme_bw() +
  theme(legend.position=c(.7, .4))           # Position legend inside
# This must go after theme_bw