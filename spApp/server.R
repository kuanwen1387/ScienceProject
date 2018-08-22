library(shiny)
library(quantmod)
library(plyr)
library(dplyr)
library(stringr)
library(ggplot2)
library(RMySQL)
library(lubridate)
library(e1071)
library(caret)


# Define server logic required to draw a histogram
function(input, output) {

  output$prediction = renderPrint({
    #Sentiment function
    search <- function(searchterm)
    {
      #Connect to MySQL
      myDB = dbConnect(MySQL(), user = 'kwn961', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
      query = sprintf("SELECT * FROM %s", searchterm)
      result = dbSendQuery(myDB, query)
      tweets = fetch(result, n = -1)
      tweets = data.frame(tweets)
      #tweets$created = strptime(tweets$created, "%Y-%m-%d %H:%M:%S", tz = "UTC")
      tweets$created = ymd_hms(tweets$created, tz = "UTC")
      dbClearResult(result)
      dbDisconnect(myDB)
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
      scores <- score.sentiment(Dataset$text, pos.words, neg.words)
      
      #total evaluation: positive / negative / neutral
      stat <- scores
      stat$created <- stack$created
      stat$created <- as.Date(stat$created)
      stat <- mutate(stat, tweet=ifelse(stat$score > 0, 'positive', ifelse(stat$score < 0, 'negative', 'neutral')))
      by.tweet <- group_by(stat, tweet, created)
      by.tweet <- summarise(by.tweet, number=n())
      
      return(by.tweet)
    }
    
    #Connect to MySQL
    myDB = dbConnect(MySQL(), user = 'kwn961', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
    
    #Get lowerbound1 for date
    query = "SELECT MIN(DATE_FORMAT(CREATED, '%Y-%m-%d')) FROM business"
    result = dbSendQuery(myDB, query)
    row = fetch(result, n = 1)
    dbClearResult(result)
    lowerbound1 = ymd(row[1], tz = "UTC")
    lowerbound1 = lowerbound1 - days(1)
    
    #Get lowerbound2 for date
    switch(input$select1,
           "JPY" = {query = "SELECT MIN(DATE_FORMAT(CREATED, '%Y-%m-%d')) FROM nikkei"},
           "GBP" = {query = "SELECT MIN(DATE_FORMAT(CREATED, '%Y-%m-%d')) FROM BBCBusiness"})
    result = dbSendQuery(myDB, query)
    row = fetch(result, n = 1)
    dbClearResult(result)
    lowerbound2 = ymd(row[1], tz = "UTC")
    lowerbound2 = lowerbound2 - days(1)
    
    #Get lowerbound
    lowerbound = max(c(lowerbound1, lowerbound2))
    lowerbound = date(lowerbound)
    
    #Get upperbound for date
    query = "SELECT MAX(DATE_FORMAT(CREATED, '%Y-%m-%d')) FROM business"
    result = dbSendQuery(myDB, query)
    row = fetch(result, n = 1)
    dbClearResult(result)
    upperbound = ymd(row[1], tz = "UTC")
    dbDisconnect(myDB)
    
    #Get fx data
    getFX(paste0("USD/", input$select1), from = as.character(lowerbound), to = as.character(upperbound))
    
    switch(input$select1,
           "JPY" = {fxData = data.frame(USDJPY)},
           "GBP" = {fxData = data.frame(USDGBP)})
    
    fxTrend = diff(fxData[, 1])
    
    #Assign class labels for dataset
    profor.data = data.frame(Date = as.Date(as.character()), USD = double(), Input = double(), Class = character(), stringsAsFactors = FALSE)
    
    
    tempDate = lowerbound + days(1)
    for (index in 1:length(fxTrend))
    {
      profor.data[index, 1] = tempDate
      profor.data[index, 2] = 0
      profor.data[index, 3] = 0
      
      if (fxTrend[index] > 0)
      {
        profor.data[index, 4] = "Up"
      }
      
      else
      {
        profor.data[index, 4] = "Down"
      }
      
      tempDate = tempDate + days(1)
    }
    
    #Get trend
    usdSentiment = search("businessPrep")
    
    switch(input$select1,
           "JPY" = {inputSentiment = search("nikkeiTranslatePrep")},
           "GBP" = {inputSentiment = search("BBCBusinessPrep")})
    
    getSentiment = function(sentiment, sentimentIndex, dataset)
    {
      for (index in 1:nrow(sentiment))
      {
        matchIndex = match(sentiment[index, 2], dataset[, 1])
        
        if (sentiment[index, 1]$tweet == "positive" & !is.na(matchIndex))
          dataset[matchIndex, sentimentIndex] = dataset[matchIndex, sentimentIndex] + sentiment[index, 3]$number
        
        if (sentiment[index, 1]$tweet == "negative" & !is.na(matchIndex))
          dataset[matchIndex, sentimentIndex] = dataset[matchIndex, sentimentIndex] - sentiment[index, 3]$number
      }
      
      return(dataset)
    }
    
    #Get sentiment
    tempSentiment = usdSentiment[order(usdSentiment[2]$created),]
    profor.data = getSentiment(tempSentiment, 2, profor.data)
    tempSentiment = inputSentiment[order(inputSentiment[2]$created),]
    profor.data = getSentiment(tempSentiment, 3, profor.data)
    
    profor.data[, 4] = as.factor(profor.data[, 4])
    
    indexes = sample(nrow(profor.data) * 0.9)
    profor.train = profor.data[indexes,2:4]
    profor.test = profor.data[-indexes,2:4]
    
    #Set cost range for tuning
    cost.range = c(-5, -3, -1, 1, 3, 5, 7, 9, 11, 13, 15)
    gamma.range = c(-15, -13, -11, -9, -7, -5, -3, -1, 1, 3)
    
    #Set tune control
    tune.parameters = tune.control(sampling = "cross", cross = 10)
    
    #Tune
    best.par = tune(svm, Class~., data = profor.train, ranges = list(cost = 2^cost.range, gamma = 2^gamma.range), tunecontrol = tune.parameters)
    print(best.par)
    
    #Get best cost and gamma
    best.cost = best.par$best.parameters[1, 1]
    best.gamma = best.par$best.parameters[1, 2]
    
    profor.model = svm(Class~., data = profor.train, cost = best.cost, gamma = best.gamma)
    svm.predTable = table(prediction = predict(profor.model, profor.test[, -3]), truth = profor.test[, 3])
    svm.conMatrix = confusionMatrix(svm.predTable)
    print(svm.predTable)
    print(svm.conMatrix$overall['Accuracy'])
  })
  
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
  
  output$sentiment1 <- renderPlot({
    searchterm = "businessPrep"
    
    #Connect to MySQL
    myDB = dbConnect(MySQL(), user = 'kwn961', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
    query = sprintf("SELECT * FROM %s", searchterm)
    result = dbSendQuery(myDB, query)
    tweets = fetch(result, n = -1)
    tweets = data.frame(tweets)
    #tweets$created = strptime(tweets$created, "%Y-%m-%d %H:%M:%S", tz = "UTC")
    tweets$created = ymd_hms(tweets$created, tz = "UTC")
    dbClearResult(result)
    dbDisconnect(myDB)
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
    scores <- score.sentiment(Dataset$text, pos.words, neg.words)
    
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
      ggtitle("USD")
  })
  
  output$sentiment2 <- renderPlot({
    switch(input$select1,
           "JPY" = {searchterm = "nikkeiTranslatePrep"},
           "GBP" = {searchterm = "BBCBusinessPrep"})
    
    #searchterm = "WSJPrep"
    
    #Connect to MySQL
    myDB = dbConnect(MySQL(), user = 'kwn961', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
    query = sprintf("SELECT * FROM %s", searchterm)
    result = dbSendQuery(myDB, query)
    tweets = fetch(result, n = -1)
    tweets = data.frame(tweets)
    #tweets$created = strptime(tweets$created, "%Y-%m-%d %H:%M:%S", tz = "UTC")
    tweets$created = ymd_hms(tweets$created, tz = "UTC")
    dbClearResult(result)
    dbDisconnect(myDB)
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
    scores <- score.sentiment(Dataset$text, pos.words, neg.words)
    
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
      ggtitle(input$select1)
  })
  
  output$history <- renderPlot({
    switch(input$select1,
                    "JPY" = {getFX("USD/JPY")
                            chartSeries(USDJPY)},
                    "GBP" = {getFX("USD/GBP")
                            chartSeries(USDGBP)})
  })

}
