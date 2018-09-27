library(RMySQL)
library(tm)

#Preprocess raw tweets to new tables
#eg. WSJ to WSJPrep
#Table needs to be created before preprocessing
preprocess = function(database)
{
  #Connect to MySQL
  myDB = dbConnect(MySQL(), user = 'kwn', password = 'gtr351387', dbname = 'PROFOR', host = '127.0.0.1')
  query = sprintf("SELECT * FROM %s", database)
  result = dbSendQuery(myDB, query)
  tweets = fetch(result, n = -1)
  tweets = data.frame(tweets)
  tweets$created = strptime(tweets$created, "%Y-%m-%d %H:%M:%S", tz = "UTC")
  dbClearResult(result)
  tweets = data.frame(tweets)
  
  # build a corpus, and specify the source to be character vectors
  corpus = Corpus(VectorSource(tweets$text))
  
  #preprocess
  #df[, 1] = tm_map(df[,1], removePunctuation)
  
  # remove punctuation
  corpus <- tm_map(corpus, removePunctuation)
  # remove numbers
  corpus <- tm_map(corpus, removeNumbers)
  # remove URLs
  removeURL <- function(x) gsub("http[[:alnum:]]*", "", x)
  corpus <- tm_map(corpus, removeURL)
  # add two extra stop words: "available" and "via"
  myStopwords <- c(stopwords("english"))
  # convert to lower case
  corpus <- tm_map(corpus, tolower)
  # remove stopwords from corpus
  corpus <- tm_map(corpus, removeWords, myStopwords)
  
  tweets$text = corpus$content
  tweets$text = gsub("[[:blank:]]", " ", tweets$text)
  
  for (tweetIndex in 1:nrow(tweets))
  {
    query = sprintf("INSERT INTO %sPrep (text, favouriteCount, created, id, screenName, retweetCount) VALUES(\"%s\", %i, \"%s\", \"%s\", \"%s\", %i)", database, tweets[tweetIndex, 1], tweets[tweetIndex, 2], tweets[tweetIndex, 3], tweets[tweetIndex, 4], tweets[tweetIndex, 5], tweets[tweetIndex, 6])
    clearQuery = dbSendQuery(myDB, query)
    dbClearResult(clearQuery)
  }
  dbDisconnect(myDB)
}

#Change the name to preprocess desired table
database = "business"
preprocess(database)
