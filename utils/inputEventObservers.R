library(shiny)
library(xtable)
library(BrAPI)
source("./utils/getTraitNames.R")

#
# Update the Gentotyping Projects
#
onDatabaseChange = function(input, output, session, data) {
  choices = list()
  db_name = input$database

  if ( db_name != "" ) {
    withProgress(message = "Fetching Genotyping Projects", value = NULL, {

      # Set geno proj choices (key = project name, value = project id)
      db = DATABASES[[db_name]]
      resp = db$wizard("genotyping_projects")
      choices = resp$data$map
      data$all_projects = resp$data$map
    })
  }

  # Update the drop down menu choices
  updateSelectInput(session, "genotyping_projects", choices = choices)
}


#
# Add the selected trials to the selected_trials table
#
onAddProjects = function(input, output, session, data) {
  selected_project_ids = input$genotyping_projects

  # Loop through each id of the selected project ids
  for ( id in selected_project_ids ) {

    # Only add the project if it's not already in the table
    if ( ! id %in% data$selected_projects$projectId ) {

      # Add the project metadata to the table of selected trials
      data$selected_projects = add_row(data$selected_projects, tibble(
        projectId = as.numeric(id),
        projectName = as.character(names(which(data$all_projects == id)))
      ))
    }
  }

  # Render the table in the UI
  output$selected_projects = renderDT(data$selected_projects)
}


#
# Remove all of the trials from the selected_trials table
#
onRemoveProjects = function(input, output, session, data) {
  data$selected_trials = data$selected_trials[0,]
  output$selected_trials = renderDT(data$selected_trials)
}


#
# Download Archived VCF Files for selected projects
#
getArchivedVCF = function(input, output, session, data) {
  selected_project_ids = data$selected_projects$projectId
  selected_project_names = data$selected_projects$projectName
  data$archived_vcf_files = c()
  
  db_name = input$database
  db = DATABASES[[db_name]]
  
  withProgress(message = "Downloading VCF Files...", value = 0, {
    for ( i in c(1:length(selected_project_ids)) ) {
      id = selected_project_ids[i]
      name = selected_project_names[i]
      path = paste0("data/", name, ".vcf")
      data$archived_vcf_files = c(data$archived_vcf_files, path)
      
      print("---- DOWNLOAD VCF FILE -----")
      print(id)
      print(name)
      
      incProgress(i/length(selected_project_ids), detail = paste("Downloading Project", name))
      
      files = db$vcf_archived_list(genotyping_project_id = id)
      print(files)
      for ( j in nrow(files) ) {
        file = files[j,]
        print(".......")
        print(paste("Starting", file$file_name))
        db$vcf_archived(path, genotyping_project_id = id, file_name = file$file_name)
        print("...finished")
      }
    }
  })
}


startQC = function(input, output, session, data) {
  print("...starting QC")
  data$k_list = perform_qc(data$archived_vcf_files)
}

startCombine = function(input, output, session, data) {
  print("...starting combine")
  data$psi = perform_combine(data$k_list)
  
  output$psi_results = renderDT(data$psi)
  output$download <- downloadHandler(
    filename = function(){"grm.csv"}, 
    content = function(fname){
      write.csv(data$psi, fname)
    }
  )
}
