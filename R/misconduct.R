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
#' @export
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



#' Extract people's names from a file or website
#' 
#' @description
#' This uses natural language processing to find all potential human names in a web page or file (ideally plain text; csv works). The code within has been developed with the help of Lincoln Mullen's natural-language-processing guide (https://rpubs.com/lmullen/nlp-chapter). However, if you already have people's names (say, at a meeting registration), just use that vector directly -- this function might miss or split names it does not recognize.
#' 
#' @details 
#' This can use either a URL or file (entered by the con argument) or a vector of text (text). If text is not NULL, it will use the text; otherwise it will use con.
#' @param con A connection object or a character string
#' @param text Raw text
#' @param ... Other arguments to pass to readLines
#' @return A vector of people's names
#' @export
#' @examples
#' nasem <- extract_people(con="http://www.nasonline.org/member-directory/living-member-list.html")
extract_people <- function(con=NULL, text=NULL, ...) {
	if(is.null(text)) {
		info <- readLines(con, ...)
	} else {
		info <- text
	}
	info <- paste(info, collapse = ", ")
	info <- gsub("\n", ", ", info)
	info <- rvest::html_text(xml2::read_html(info))
	info <- NLP::as.String(info)
	sent_ann <- openNLP::Maxent_Sent_Token_Annotator()
	word_ann <- openNLP::Maxent_Word_Token_Annotator()

	person_ann <- openNLP::Maxent_Entity_Annotator(kind = "person")
	info_annotations <- NLP::AnnotatedPlainTextDocument(info, NLP::annotate(info, list(sent_ann, word_ann, person_ann)))
	info_annotations_df <- as.data.frame(info_annotations[[2]])
	info_annotations_df$features <- unname(simplify2array(lapply(info_annotations_df$features, unlist)))
	focal_info <- subset(info_annotations_df, features=="person")
	people <- rep(NA, nrow(focal_info))
	for (i in sequence(nrow(focal_info))) {
		people[i] <- substr(NLP::content(info_annotations), start=focal_info$start[i], stop=focal_info$end[i])
	}
	return(people)
}

#' Format first and last name
#' 
#' @description
#' Uses the humaniform package to get the first and last name.
#' @param people A character vector of people's names
#' @param remove_odd If TRUE, delete names that might have been errors: NA, "A.", etc.
#' @return A data.frame with columns first_name and last_name
#' @export
format_people <- function(people, remove_odd=FALSE) {
	parsed_names <- humaniformat::parse_names(people)
	if(remove_odd) {
		parsed_names <- parsed_names[!is.na(parsed_names$last_name),]
		parsed_names <- parsed_names[!is.na(parsed_names$first_name),]
		parsed_names <- parsed_names[!grepl("\\.", parsed_names$last_name), ]
	}
	return(parsed_names[,c("first_name", "last_name")])
}

#' Find matches
#' 
#' @description
#' Finds which people in the pool match people in the known group; returns potential matches for each. Remember that there may be both false positives (different people with similar or identical names) and false negatives (people who don't match since their names aren't similar enough ("Ann Doe" and "Nancy Doe")).
#' 
#' @details 
#' The fraction_firstname_mismatch_allowed goes from 0 to 1; if 0, every letter in both first names must match exactly; if 1, every letter can be different. The default value allows for some mismatch ("Will" and "Billy"). Higher values lead to more false positives but fewer false negatives (though even the extremes still allow some of each).
#' 
#' If the pool of names comes from, say, natural language processing of a website, there may be incorrect names included. remove_odd_pool=TRUE will remove these from the pool ("people" with no first name, no last name, or a period in their last name). If you know this isn't an issue, then set this to FALSE
#' @param pool Vector of people to check against a known database
#' @param misconduct_db Tibble of people and other information in a misconduct database.
#' @param remove_odd_pool If TRUE, delete names that might have been errors: NA, "A.", etc.
#' @param fraction_firstname_mismatch_allowed What fraction of letters can be different between the first names to count as a match
#' @examples 
#' nasem <- extract_people(con="http://www.nasonline.org/member-directory/living-member-list.html")
#' asmd <- get_misconduct(agree=TRUE)
#' apparent_matches <- match_misconduct(nasem, asmd)
#' print(apparent_matches[,c("Pool", "Person", "FirstNameMismatchFraction", "Specific Outcome")])
#' @export 
#' @return A tibble that has the rows of misconduct_db who may match the people in the pool along with the people in the pool who might match and the fraction of letters in their first names that don't match(the first two columns, Pool and FirstNameMismatchFraction)
match_misconduct <- function(pool, misconduct_db, remove_odd_pool=TRUE, fraction_firstname_mismatch_allowed=0.7) {
	pool_names <- format_people(pool, remove_odd=remove_odd_pool)
	misconduct_names <- format_people(misconduct_db$Person)
	#potential_matches <- rep(NA, nrow(pool_names))
	misconduct_db <- tibble::add_column(misconduct_db, Pool="")
	misconduct_db <- tibble::add_column(misconduct_db, FirstNameMismatchFraction=1)

	final_matches <- misconduct_db[0,]
	for (i in sequence(nrow(pool_names))) {
		lastname_match <- which(tolower(misconduct_names$last_name)==tolower(pool_names$last_name[i]))
		if(length(lastname_match)>0) {
			for (j in seq_along(lastname_match)) {
				mismatch_fraction <- utils::adist(tolower(pool_names$first_name[i]), tolower(misconduct_names$first_name[lastname_match[j]]))[1,1]/min(c(nchar(pool_names$first_name[i]), nchar(misconduct_names$first_name[lastname_match[j]])))
				if(mismatch_fraction <= fraction_firstname_mismatch_allowed ) {
					final_matches <- rbind(final_matches, misconduct_db[lastname_match[j],]) #yes, this is slow
					final_matches$Pool[nrow(final_matches)] <- paste(pool_names$first_name[i], pool_names$last_name[i])
					final_matches$FirstNameMismatchFraction[nrow(final_matches)] <- mismatch_fraction

				}
			}
		}
	}
	final_matches <- dplyr::relocate(final_matches, Person)

	final_matches <- dplyr::relocate(final_matches, FirstNameMismatchFraction)
	final_matches <- dplyr::relocate(final_matches, Pool)

	return(final_matches)
}