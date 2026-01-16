library(shiny)
library(BrAPI)
library(tidyverse)

source("utils/inputEventObservers.R")
source("analyses/em_covariance_combiner.R")
source("analyses/Estimate_GRM_list.R")
source("analyses/Estimate_combinedGRM.R")


# ====================================================== #
#
# SHINY SERVER
# This file defines the backend functionality of the app
# It handles changes to inputs and generates the outputs
#
# ====================================================== #


server = function(input, output, session) {


  #
  # REACTIVE DATA
  # This is data that will be set and used in different
  # functions of the server, such as the tables of 
  # selected trials and their downloaded phenotypes
  #
  data = reactiveValues(
    all_projects = list(),
    selected_projects = tibble(
      projectId = numeric(),
      projectName = character()
    ),
    archived_vcf_files = c(),
    k_list = list(),
    psi = tibble()
  )


  #
  # HANDLER: Database Selection
  # Update the choices for breeding program when the selected database changes
  #
  observeEvent(input$database, onDatabaseChange(input, output, session, data))



  #
  # HANDLER: Add Projects Button
  # Add the user-selected trials to the table
  #
  observeEvent(input$add_projects, onAddProjects(input, output, session, data))


  #
  # HANDLER: Remove Projects Button
  # Clear all selected trials from the table
  #
  observeEvent(input$remove_projects, onRemoveProjects(input, output, session, data))


  #
  # HANDLER: Download Archived VCF
  # Download all observations for all selected trials
  #
  observeEvent(input$fetch_archived_vcf, getArchivedVCF(input, output, session, data))


  #
  # HANDLER: Start QC
  # Allow the user to upload a table of phenotypes, parse as data$phenotype_data
  #
  observeEvent(input$start_qc, startQC(input, output, session, data))
  
  #
  # HANDLER: Start Combine
  # Allow the user to upload a table of phenotypes, parse as data$phenotype_data
  #
  observeEvent(input$start_combine, startCombine(input, output, session, data))


  #
  # HANDLER: Download Phenotypes
  # Download the current phenotype_data table to a CSV file
  #
  output$download_phenotype_data = downloadPhenotypeData(input, output, session, data)


  #
  # HANDLER: Upload Marker Data
  # Allow the user to upload a table of marker data, parse as data$marker_data
  #
  observeEvent(input$upload_genotype_data, onUploadGenotypeData(input, output, session, data))


  #
  # HANDLER: Start Analysis
  # Start the analysis script with the chosen input
  #
  observeEvent(input$start_analysis, onStartAnalysis(input, output, session, data))
}