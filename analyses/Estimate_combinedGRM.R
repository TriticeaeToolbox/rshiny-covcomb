#################################################
# Estimate the combined relationship matrix 
############################################
# Estimate the combined relationship matrix 
#############################################
#Set condition to continue combining the genomic relationship matrix 


runCombine = function(K_list) {
  
  acc_com_list <- list()
  Tot_acc <- c()
  for(ls in 1:length(K_list)){
    gn <- rownames(K_list[[ls]])
    acc_com_list[[ls]] <- gn
    Tot_acc <- unique(c(Tot_acc,gn))
  }
  
  comm_acc <- Reduce(intersect, acc_com_list)
  
  indexes <- list()
  K_list_index <- K_list
  if(length(comm_acc) > 3){
    for(id in 1:length(K_list)){
      idx <- 0:(length(Tot_acc)-1)
      idx_sum <- data.frame(index = idx, Accession = Tot_acc)
      ida <- which(idx_sum$Accession %in% rownames(K_list[[id]]))
      indxac1 <- idx_sum$index[ida]
      indexes[[id]] <- indxac1
      rownames(K_list_index[[id]]) <- NULL
      colnames(K_list_index[[id]]) <- NULL
    }
  }
  else {
    showNotification("There are not enough common accessions", duration=NULL, type="error")
    return()
  }
  
  #combine the genomic relationship matrices
  Df <- rep(100, length(K_list))
  combcov <- EMCovarianceCombiner(partial_covs = K_list_index, 
                                  var_indices = indexes,
                                  degrees_freedom = Df
  )
  #Renaming the column name 
  rownames(combcov$psi) <- Tot_acc
  colnames(combcov$psi) <- Tot_acc
  
  showNotification("GRM combination complete", duration=30, type="message")
  return(combcov$psi)
  
}