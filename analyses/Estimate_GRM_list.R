########################
# estimate_GRM_list from genotyping projects 

runQC = function(vcf_file_paths) {


  #####################################
  # Read the VCF file 
  #####################################
  library(vcfR)
  K_list <- list()
  withProgress(message = "Reading VCF Files", value = NULL, {
    for( i in c(1:length(vcf_file_paths)) ) {
      path = vcf_file_paths[i]
      incProgress(i/length(vcf_file_paths), detail = path)
      
      vcf11 <- vcfR::read.vcfR(file = path,convertNA = T)
      
      snp11 <- vcfR::extract.gt(vcf11, # TODO
                                element = "GT",
                                IDtoRowNames  = F,
                                as.numeric = T,
                                convertNA = T,
                                return.alleles = F)
      snps_num_t <- t(snp11) 
      #remove Na 
      snps_num_df <- data.frame(snps_num_t) 
      
      ##################################################################
      # QC - of the data - Remove markers with NA values more than 20%
      # filter the snp data with MAF of 0.05
      ##################################################################
      mark_na <- c()
      for(cl in 1:ncol(snps_num_df)){
        if(length(which(is.na(snps_num_df[,cl]))) > .2*nrow(snps_num_df)){
          mark_na <- c(mark_na,cl)
        }
      }
      
      if(length(mark_na) > 0){
        snps_num_df_wo_na <- snps_num_df[,-mark_na]
      }else{
        snps_num_df_wo_na <- snps_num_df
      }
      
      dim(snps_num_df_wo_na)
      
      ################################
      #Filter with MAF (0.05)
      ################################
      library(genomicMateSelectR)
      
      snps_num_maf <- maf_filter(M = snps_num_df_wo_na, thresh = 0.05 )
      dim(snps_num_maf)
      
      #Estimate the genomic relationship matrix 
      sn_av <- apply(X = snps_num_maf, MARGIN = 2,FUN = mean, na.rm = T)
      for(z in 1:ncol(snps_num_maf)){
        idz <- which(is.na(snps_num_maf[,z]))
        snps_num_maf[idz,z] <- sn_av[z]
        
      }
      snps_num_maf <- as.matrix(snps_num_maf)
      
      #############################################
      # Estimate the genomic relationship matrix 
      ##############################################
      K <- kinship(M = snps_num_maf, type = "add")
      K <- K + diag(1e-6, ncol(K))
      K_list[[path]] <- K
    }
  })
  
  showNotification("QC Complete", duration=30, type="message")
  
  return(K_list)

}
