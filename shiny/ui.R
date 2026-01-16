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

    # The left column has the trial selection and analysis parameter inputs
    column(6,

      # Download Data via BrAPI
      wellPanel( 
        h3("Fetch Data from Database"),
        p("Select Genotype Projects to use in the analysis."),
        
        # Dropdown menus for selecting the input trials
        # The choices for the database come from the BrAPI library
        # The choices for the breeding program will be added when the database is selected (in server.R)
        # The choices for the trials will be added when a breeding program is selected (in server.R)
        selectInput("database", "Database", choices = c("", names(DATABASES)), width="100%"),
        selectInput("genotyping_projects", "Genotyping Projects", choices = c(), width="100%", multiple=TRUE, selectize=FALSE),

        # Buttons to add / remove trials
        fluidRow(
          column(6, actionButton("add_projects", "Add Genotyping Projects to Selection")),
          column(6, actionButton("remove_projects", "Remove All Selected Genotyping Projects"))
        ),
        
        tags$hr(),

        # Button to download trials
        actionButton(
          "fetch_archived_vcf",
          "Download VCF for Selected Projects",
          icon("database"),
          style = "color: #fff; background-color: #337ab7; border-color: #2e6da4"
        )
        
      ),

    ),

    # The right column has a table of the selected trials
    column(4,
      h3("Selected Genotyping Projects"),
      dataTableOutput("selected_projects"),
    ),

    style = "margin-top: 80px"
  )
)

#
# GENOTYPE DATA PANEL
#
genotypePanel = fluidPage(

  # A row with two columns
  fluidRow(

    # Left column: genotype file selection
    column(6,

      # Upload Data from File
      wellPanel(
        h3("Upload Data from Files"),
        p("Upload a Dosage Matrix file for use in the analysis."),

        fileInput("upload_genotype_data", "Upload Marker Data")
      )

    ),

    # Right column:
    column(8,

      h3("Genotype Data"),
      dataTableOutput("genotype_data")

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

    # Left column: button to download phenotypes
    column(3,
      wellPanel(

        h4("Step 1"),
        p("Quality Control"),
        actionButton("start_qc", "Start Quality Control"),
        
        hr(),

        h4("Step 2"),
        p("Combine GRMs"),
        actionButton("start_combine", "Start Combine GRMs")

      )
    ),

    # Right column: table of selected phenotypes
    column(9,
      h3("Analysis Results"),

      hr(),
      h4("GRM Results"),
      dataTableOutput("psi_results"),
      
      downloadButton('download',"Download the GRM"),

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
  tabPanel("Select Data", dataPanel, icon = icon("dna")),
  tabPanel("Run Analysis", analysisPanel, icon = icon("play")),

  # Set the navbar to be "sticky" at the top
  position = "fixed-top",

  # Add custom css to move the notification panel to the top-right corner of the page
  header = tags$head(
    tags$style(".shiny-notification { position: fixed; top: 5px; right: 15px; width: 300px }"),
    tags$style(".progress-message, .progress-detail { display: block }")
  )

)