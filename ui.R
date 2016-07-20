
library(shiny)

fluidPage(
  actionButton("show", "Login"),
  verbatimTextOutput("dataInfo")
)