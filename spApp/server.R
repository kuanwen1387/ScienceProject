library(shiny)
library(quantmod)
library(plyr)
library(dplyr)
library(stringr)
library(ggplot2)
library(RMySQL)
library(lubridate)

# Define server logic required to draw a histogram
function(input, output) {

  output$tweets <- renderTable({
    #Connect to MySQL
    myDB = dbConnect(MySQL(), user = 'kwn961', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
    query = paste0("SELECT * FROM ", input$select2)
    result = dbSendQuery(myDB, query)
    rows = fetch(result, n = -1)
    dbClearResult(result)
    dbDisconnect(myDB)
    tweets.df = rows
    tweets.df
  })
  
  output$sentiment <- renderPlot({
    searchterm = "WSJprep"
    
    #Connect to MySQL
    myDB = dbConnect(MySQL(), user = 'kwn961', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
    query = sprintf("SELECT * FROM %s", searchterm)
    result = dbSendQuery(myDB, query)
    tweets = fetch(result, n = -1)
    tweets = data.frame(tweets)
    #tweets$created = strptime(tweets$created, "%Y-%m-%d %H:%M:%S", tz = "UTC")
    tweets$created = ymd_hms(tweets$created, tz = "UTC")
    dbClearResult(result)
    stack = data.frame(tweets)
    
    #evaluation tweets function
    score.sentiment <- function(sentences, pos.words, neg.words, .progress='none')
    {
      require(plyr)
      require(stringr)
      scores <- laply(sentences, function(sentence, pos.words, neg.words){
        word.list <- str_split(sentence, '[[:blank:]]')
        words <- unlist(word.list)
        pos.matches <- match(words, pos.words)
        neg.matches <- match(words, neg.words)
        pos.matches <- !is.na(pos.matches)
        neg.matches <- !is.na(neg.matches)
        score <- sum(pos.matches) - sum(neg.matches)
        return(score)
      }, pos.words, neg.words, .progress=.progress)
      scores.df <- data.frame(score=scores, text=sentences)
      return(scores.df)
    }
    
    pos.words <- scan('positive.txt', what='character', comment.char=';') #folder with positive dictionary
    neg.words <- scan('negative.txt', what='character', comment.char=';') #folder with negative dictionary
    
    Dataset <- stack
    Dataset$text <- as.factor(Dataset$text)
    scores <- score.sentiment(Dataset$text, pos.words, neg.words, .progress='text')
    
    #total evaluation: positive / negative / neutral
    stat <- scores
    stat$created <- stack$created
    stat$created <- as.Date(stat$created)
    stat <- mutate(stat, tweet=ifelse(stat$score > 0, 'positive', ifelse(stat$score < 0, 'negative', 'neutral')))
    by.tweet <- group_by(stat, tweet, created)
    by.tweet <- summarise(by.tweet, number=n())
    
    #create chart
    ggplot(by.tweet, aes(created, number)) + geom_line(aes(group=tweet, color=tweet), size=2) +
      geom_point(aes(group=tweet, color=tweet), size=4) +
      theme(text = element_text(size=18), axis.text.x = element_text(angle=90, vjust=1)) +
      #stat_summary(fun.y = 'sum', fun.ymin='sum', fun.ymax='sum', colour = 'yellow', size=2, geom = 'line') +
      ggtitle(searchterm)
  })
  
  output$history <- renderPlot({
    switch(input$select1,
                    "EUR" = {getFX("USD/EUR")
                            chartSeries(USDEUR)},
                    "JPY" = {getFX("USD/JPY")
                            chartSeries(USDJPY)},
                    "GBP" = {getFX("USD/GBP")
                            chartSeries(USDGBP)})
  })

}
