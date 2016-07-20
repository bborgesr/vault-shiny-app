
library(shiny)
library(pool)
source("api-test.R")

function(input, output) {
  pool <- NULL
  values <- reactiveValues(authenticated = FALSE)
  
  # Return the UI for a modal dialog with data selection input. If 'failed' 
  # is TRUE, then display a message that the previous value was invalid.
  dataModal <- function(failed = FALSE) {
    modalDialog(
      textInput("username", "username"),
      passwordInput("password", "password"),
      if (failed)
        div(tags$b("Invalid credentials", style = "color: red;")),
      
      footer = tagList(
        modalButton("Cancel"),
        actionButton("ok", "OK")
      )
    )
  }
  
  # Show modal when button is clicked.
  observeEvent(input$show, {
    showModal(dataModal())
  })
  
  createPool <- function() {
    pool <<- NULL
    data <- content(GET('http://127.0.0.1:8200/v1/secret/credentials',
                        add_headers(`X-Vault-Token` = client_token)))$data
    user <- data$username
    pw <- data$password 
    try( pool <<- dbPool(
      drv = RMySQL::MySQL(),
      dbname = "shinydemo",
      host = "shiny-demo.csa7qlmguqrf.us-east-1.rds.amazonaws.com",
      username = user,
      password = pw
    ))
    if (!is.null(pool)) TRUE
    else FALSE
  }
  
  # When OK button is pressed, attempt to authenticate. If successful,
  # remove the modal. If not, show another modal, but this time with a 
  # failure message.
  observeEvent(input$ok, {
    POST('http://127.0.0.1:8200/v1/secret/credentials',
         add_headers(`X-Vault-Token` = client_token,
                     `Content-type` = "application/json"),
         body = paste0('{"username": "', input$username, '",',
                       ' "password": "', input$password, '"}'),
         encode = 'json')
    
    # Check that data object exists and is data frame.
    if (createPool()) {
      values$authenticated <- TRUE
      removeModal()
    } else {
      values$authenticated <- FALSE
      showModal(dataModal(failed = TRUE))
    }
  })
  
  # show pool
  output$dataInfo <- renderPrint({
    if (values$authenticated) dbGetInfo(pool)
    else "You are NOT authenticated"
  })
}