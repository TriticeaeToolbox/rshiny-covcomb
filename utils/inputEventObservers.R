library(shiny)
library(xtable)
library(BrAPI)

#
# Database Changed: update available projects
#
onDatabaseChange = function(input, output, session, data) {
  choices = list()
  db_name = input$selectDatabase
  data$selected_projects = data$selected_projects[0,]

  if ( db_name != "" ) {
    withProgress(message = "Fetching Genotyping Projects", value = NULL, {
      tryCatch({
        db = DATABASES[[db_name]]
        resp = db$wizard("genotyping_projects")
        choices = resp$data$map
        data$all_projects = resp$data$map
      },
      error = function() {
        showNotification("Could not fetch genotyping projects", duration=NULL, type="error")
      })
    })
  }

  # Update the drop down menu choices
  updateSelectInput(session, "selectProjects", choices = choices)
}


#
# Add the selected trials to the selected_trials table
#
onAddProjects = function(input, output, session, data) {
  selected_project_ids = input$selectProjects

  # Loop through each id of the selected project ids
  for ( id in selected_project_ids ) {

    # Only add the project if it's not already in the table
    if ( ! id %in% data$selected_projects$id ) {

      # Add the project metadata to the table of selected trials
      data$selected_projects = add_row(data$selected_projects, tibble(
        id = as.numeric(id),
        name = as.character(names(which(data$all_projects == id)))
      ))
    }
  }

  # Render the table in the UI
  output$selectedProjects = renderDT(data$selected_projects)
}


#
# Remove all of the trials from the selected_trials table
#
onRemoveProjects = function(input, output, session, data) {
  data$selected_projects = data$selected_projects[0,]
  output$selectedProjects = renderDT(data$selected_projects)
}


#
# Download Archived VCF Files for selected projects
#
onDownloadVCF = function(input, output, session, data) {
  selected_project_ids = data$selected_projects$id
  selected_project_names = data$selected_projects$name
  data$vcf_files = c()
  
  # Return an error if there are no selected projects
  if ( length(selected_project_ids) < 1 ) {
    showNotification("There are no selected genotyping projects", duration=NULL, type="error")
    return()
  }
  
  # Get DB to use
  db_name = input$selectDatabase
  db = DATABASES[[db_name]]
  
  # Download each VCF File
  withProgress(message = "Downloading VCF Files...", value = 0, {
    for ( i in c(1:length(selected_project_ids)) ) {
      id = selected_project_ids[i]
      name = selected_project_names[i]

      print("---- DOWNLOAD VCF FILE -----")
      print(id)
      print(name)
      
      # increment the progress bar
      incProgress(i/length(selected_project_ids), detail = name)
      
      # fetch all of the archived files for this project
      files = db$vcf_archived_list(genotyping_project_id = id)
      for ( j in nrow(files) ) {
        file = files[j,]
        print(paste("Starting file: ", file$file_name))
        
        # download the specific archived file
        path = paste("data", file$file_name, sep="/")
        if ( !file.exists(path) ) {
          db$vcf_archived(path, genotyping_project_id = id, file_name = file$file_name)
          print("...finished")
        }
        else {
          print("...file already exits (skipping download)")
        }
        data$vcf_files = c(data$vcf_files, path)
      }
    }
  })
  
  output$availableVCF = renderUI({
    HTML(paste0(
      "<ul><li>",
      paste(data$vcf_files, collapse="</li><li>"),
      "</li></ul>"
    ))
  })
}


onStartQC = function(input, output, session, data) {
  print("...starting QC")
  data$k_list = runQC(data$vcf_files)
}

onStartCombine = function(input, output, session, data) {
  print("...starting combine")
  data$psi = runCombine(data$k_list)
  
  output$resultsGRM = renderDT(data$psi)

  # Download GRM handler
  output$downloadGRM <- downloadHandler(
    filename = function(){"grm.csv"}, 
    content = function(fname){
      write.csv(data$psi, fname)
    }
  )
}
