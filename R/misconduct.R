#' Download and cache misconduct data
#' 
#' @description
#' Pull in information on misconduct. For now, the only source is the Academic Sexual Misconduct Database, created by Julie Libarkin, though the function is written to allow extension to other public databases.
#' 
#' @details
#' An important thing to note is the license under which the data are released: "This database includes evidenced cases of academic sexual misconduct and cases where relationship policies were violated. All cases are based on publicly available documents or media reports, and only cases documented publicly can be included." The full legal information is at https://academic-sexual-misconduct-database.org/legal. You must read this before using the dataset.
#' 
#' Anyone using the Academic Sexual Misconduct Database should reference it as written below. Since the database is continually updated, the retrieval date is particularly important:
#' 
#' Libarkin, J. (2020). Academic Sexual Misconduct Database. Retrieved MONTH/DAY/YEAR, from https://academic-sexual-misconduct-database.org
#' 
#' @param source Which database to use, currently just ASMD
#' @param agree If TRUE, shows you have read and agree with the database terms
#' @return A tibble with the database contents
#' @examples 
#' known <- get_misconduct(agree=TRUE)
get_misconduct <- function(source="ASMD", agree=FALSE) {
	if(!agree) {
		stop("You must agree to the license for the use of the data before its use")
	}
	if(source=="ASMD") {
		asmd_client <- crul::HttpClient$new(url = "https://academic-sexual-misconduct-database.org/incidents/download_excel")
		tmp <- file.path(tempdir(), 'asmd.xlsx')
		res <- asmd_client$get(disk = tmp)
		known <- readxl::read_excel(tmp)
	}
	return(known)
}