#Libraries
library(twitteR)
library(RMySQL)
library(rjson)

#Authentication credentials for twitter API
#You get the credentials from your twitter account
api_key = 'p5kQMvfG7UMXR2pR5rXCd2Nev'
api_secret = 'uI0NfUuZUNjDTc4kbJ2gWYK9KFJzARrNzJIX26sq1bOCKtD7Vb'
access_token = '732937169556250624-iOmkeUyZgOQryKfrfmlk7Iyf6dkYYkC'
access_token_secret = 'If42zMHPyQBufqD6wywsJZDEthiZ4oqS5WCoGNh144gJh'

#Twitter authentication
setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)

#create chunks function
chunk2 <- function(x,n) split(x, cut(seq_along(x), n, labels = FALSE))

#load ids
ids_WSJ = fromJSON(file = "WSJ.json")
ids_BW = fromJSON(file = "BW.json")
ids_business = fromJSON(file = "business.json")
ids_FinancialTimes = fromJSON(file = "FinancialTimes.json")
ids_BBCBusiness = fromJSON(file = "BBCBusiness.json")

#Get tweets function
get_tweets = function(ids, dbname)
{
  #build chunk size bbc
  chunk_size = ceiling(length(ids)/100)
  ids_part = chunk2(ids, chunk_size)
  
  #Build dataframe
  tempData = lookup_statuses(unlist(ids_part[1]))
  tweets.df = twListToDF(tempData)
  
  #Get tweets
  for (index in 2:length(ids_part))
  {
    tempData = lookup_statuses(unlist(ids_part[index]))
    temp.df = twListToDF(tempData)
    
    tweets.df = rbind(tweets.df, temp.df)
  }
  
  #sort dataframe
  tweets.sort.df = tweets.df[order(tweets.df$created),]
  
  #remove punct
  tweets.sort.df$text = gsub('"', '', tweets.sort.df$text)
  
  #Connect to MySQL
  myDB = dbConnect(MySQL(), user = 'kwn', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
  
  #insert bbc
  for (tweetIndex in 1:nrow(tweets.sort.df))
  {
    query = sprintf("INSERT INTO %s (text, favouriteCount, created, id, screenName, retweetCount) VALUES(\"%s\", %i, \"%s\", \"%s\", \"%s\", %i)", dbname, tweets.sort.df[tweetIndex, 1], tweets.sort.df[tweetIndex, 3], tweets.sort.df[tweetIndex, 5], tweets.sort.df[tweetIndex, 8], tweets.sort.df[tweetIndex, 11], tweets.sort.df[tweetIndex, 12])
    clearQuery = dbSendQuery(myDB, query)
    dbClearResult(clearQuery)
  }
  
  dbDisconnect(myDB)
}

#Get tweets
get_tweets(ids_WSJ, "WSJ")
get_tweets(ids_BW, "BW")
get_tweets(ids_business, "business")
get_tweets(ids_FinancialTimes, "FinancialTimes")
get_tweets(ids_BBCBusiness, "BBCBusiness")
