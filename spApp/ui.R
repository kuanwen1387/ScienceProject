shinyUI(fluidPage(
  
  titlePanel("TWFX"),
  
  sidebarLayout(
    
    sidebarPanel(
      selectInput("select1", label = h3("Currency:"), 
                  choices = c("JPY" = "JPY", "GBP" = "GBP"), selected = "JPY"),
      selectInput("select2", label = h3("Tweets:"), 
                  choices = c("business" = "business", "nikkei" = "nikkei", "BBCBusiness" = "BBCBusiness"), selected = "business"),
      submitButton("Submit")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Prediction", verbatimTextOutput("prediction")),
        tabPanel("Tweets", tableOutput("tweets")),
        tabPanel("USD Sentiment", plotOutput("sentiment1")),
        tabPanel("Input Sentiment", plotOutput("sentiment2")),
        tabPanel("Currency History", plotOutput("history"))
      )
    )
  )
))
