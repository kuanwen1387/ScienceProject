shinyUI(fluidPage(
  
  titlePanel("TWFX"),
  
  sidebarLayout(
    
    sidebarPanel(
      selectInput("select1", label = h3("Currency:"), 
                  choices = c("EUR" = "EUR", "JPY" = "JPY",
                                 "GBP" = "GBP"), selected = "EUR"),
      selectInput("select2", label = h3("Tweets:"), 
                  choices = c("USD" = "WSJ", "EUR" = "handelsblatt", "JPY" = "nikkei",
                              "GBP" = "FinancialTimes"), selected = "USD"),
      submitButton("Submit")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Prediction", verbatimTextOutput("text")),
        tabPanel("Tweets", tableOutput("tweets")),
        tabPanel("Twitter Sentiment", plotOutput("sentiment")), 
        tabPanel("Currency History", plotOutput("history"))
      )
    )
  )
))
