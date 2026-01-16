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
  # functions of the server, such as the selected input 
  # data and any generated output data
  #
  data = reactiveValues(
    all_projects = list(),
    selected_projects = tibble(
      id = numeric(),
      name = character()
    ),
    vcf_files = c(),
    k_list = list(),
    psi = tibble()
  )


  #
  # HANDLER: Database Selection
  # Update the list of genotyping projects when the database changes
  #
  observeEvent(input$selectDatabase, onDatabaseChange(input, output, session, data))



  #
  # HANDLER: Add Projects Button
  # Add the user-selected projects to the table
  #
  observeEvent(input$addProjects, onAddProjects(input, output, session, data))


  #
  # HANDLER: Remove Projects Button
  # Clear all selected projects from the table
  #
  observeEvent(input$removeProjects, onRemoveProjects(input, output, session, data))


  #
  # HANDLER: Download Archived VCF
  # Download all vcf files for the selected projects
  #
  observeEvent(input$downloadVCF, onDownloadVCF(input, output, session, data))


  #
  # HANDLER: Start QC
  #
  observeEvent(input$startQC, onStartQC(input, output, session, data))
  
  #
  # HANDLER: Start Combine
  #
  observeEvent(input$startCombine, onStartCombine(input, output, session, data))

}