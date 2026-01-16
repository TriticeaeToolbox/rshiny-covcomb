library(shiny)
library(DT)
library(BrAPI)


# ====================================================== #
#
# SHINY UI
# This file defines the user interface of the shiny app
#
# ====================================================== #


#
# SUPPORTED DATABASES
# The list of supported databases and their connection info
# These are defined in the BrAPI R library
#
DATABASES = getBrAPIConnections()
DATABASES = DATABASES[order(names(DATABASES))]


#
# DATA PANEL
#
dataPanel = fluidPage(

  # Create a Row with two Columns
  fluidRow(

    # The left column has the database and genotype project selection
    column(6,

      # Download Data via BrAPI
      wellPanel( 
        h3("Fetch Data from Database"),
        p("Select Genotype Projects to use in the analysis."),
        
        # Dropdown menus for selecting the input data
        # The choices for the database come from the BrAPI library
        # The choices for the genotyping projects will be updated when a database is selected
        selectInput("selectDatabase", "Database", choices = c("", names(DATABASES)), width="100%"),
        selectInput("selectProjects", "Genotyping Projects", choices = c(), width="100%", multiple=TRUE, selectize=FALSE),

        # Button to add projects to selection
        actionButton(
          "addProjects", 
          "Add Genotyping Projects to Selection",
          icon("check")
        ),
        
        tags$hr(),

        # Button to download data
        actionButton(
          "downloadVCF",
          "Download VCF for Selected Projects",
          icon("download"),
          style = "color: #fff; background-color: #337ab7; border-color: #2e6da4"
        ),
        
        tags$hr(),
        
        h3("Downloaded VCF Files:"),
        htmlOutput("availableVCF") 
        
      ),

    ),

    # The right column has a table of the selected projects
    column(4,
      h3("Selected Genotyping Projects"),
      dataTableOutput("selectedProjects"),
      
      tags$hr(),
      
      # Button to clear selected projects
      actionButton(
        "removeProjects",
        "Remove All Selected Genotyping Projects",
        icon("eraser"),
        style = "color: #fff; background-color: #dc3545; border-color: #c11626"
      )
    ),

    style = "margin-top: 80px"
  )
)


#
# ANALYSIS PANEL
#
analysisPanel = fluidPage(

  # A row with two columns
  fluidRow(

    # Left column: buttons to run each step
    column(3,
      wellPanel(

        h4("Step 1"),
        p("Quality Control"),
        actionButton("startQC", "Start Quality Control"),
        
        hr(),

        h4("Step 2"),
        p("Combine GRMs"),
        actionButton("startCombine", "Start Combine GRMs")

      )
    ),

    # Right column: display of results
    column(9,
      h3("Analysis Results"),

      hr(),
      h4("GRM Results"),
      dataTableOutput("resultsGRM"),
      
      downloadButton('downloadGRM',"Download the GRM"),

    ),

    style = "margin-top: 80px"
  )

)


#
# PAGE LAYOUT
# Define the main UI as a Navbar Page
# 
# This is a toolbar with navigation bar at the top of the page
# that can be used to toggle the display of different panels
#
ui = navbarPage(

  # Toolbar title
  title = "CovComb Analysis",

  # Navigation panels
  tabPanel("Select Data", dataPanel, icon = icon("database")),
  tabPanel("Run Analysis", analysisPanel, icon = icon("play")),

  # Set the navbar to be "sticky" at the top
  position = "fixed-top",

  # Add custom css to move the notification panel to the top-right corner of the page
  header = tags$head(
    tags$style(".shiny-notification { position: fixed; top: 5px; right: 15px; width: 300px }"),
    tags$style(".progress-message, .progress-detail { display: block }")
  )

)