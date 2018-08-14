library(tidyverse)
library(stringr)
library(pbapply)
library(parallel)
library(textstem)


disclaimer1 <- "While we aim to supply accurate product information it is sourced by manufacturers suppliers and marketplace sellers and has not been provided by Overstock"
disclaimer2 <- "While we aim to supply accurate product information, it is sourced by manufacturers, suppliers and marketplace sellers, and has not been provided by Overstock"

# split_text_file(): ------------------------------------------------------
### Only works on a Unix system with coreutils installed
### If function fails with split function, try removing the g suffix from gsplit.

split_text_file <- function(in.file.path, line.count = 10000, csv = TRUE) {
  if(!file.exists(in.file.path)) {
    stop(paste("File:", in.file.path, "could not be found"))
  }
  
  filepath <- str_extract(in.file.path, ".*\\/")
  filename <- str_extract(in.file.path, "([^\\/]+)$")
  fileid <- str_extract(in.file.path, "[ \\w-]+?(?=\\.)")
  
  system(
    paste(
      paste("cd", filepath, "&& mkdir", fileid, "&& cd", fileid), "&&",
      paste0("gsplit -l ", line.count, " --numeric-suffixes ", "../", filename, " ", fileid)))
  
  if(csv == TRUE) {
    file_dir <- paste0(filepath, fileid)
    file_list <- list.files(file_dir)
    first_file <- file_list[[1]]
    col_names <- paste0(colnames(read_csv(paste0(file_dir, "/", first_file))), collapse = ", ")
    files_to_append <- file_list[-1]
  
    for(file in seq_along(files_to_append)) {
      system(
        paste0("sed  -i '' '1i\\\n",  col_names, "\n' ", paste0(file_dir, "/", files_to_append[file])))
    }
  }
  
}

# Testing
# split_text_file(in.file.path = "../data/test/test_query.csv")



# process_pipeline(): -----------------------------------------------------------

process_pipe <- function(product_text) {
  clean_df <- product_text %>% 
    unite(., text, PRO_NAME:PRO_SHORT_NAME, sep = ". ", remove = TRUE) %>% 
    mutate(text = map_chr(text, clean_text)) %>% 
    mutate(word_count = str_count(text, "\\S+"))
}



# clean_text(): -----------------------------------------------------------

clean_text <- function(text) {
  text %>% 
    gsub(disclaimer, "", ., fixed = TRUE) %>% 
    gsub(disclaimer2, "", ., fixed = TRUE) %>% 
    str_extract_all("(?!(\\bin\\b)|(\\bx\\b)|(\\bft\\b)|[^A-Za-z0-9]\\w*|(\\w*[^A-Za-z0-9 \\n])|\\d|\\bNA\\b|(?<=[^a-zA-Z0-9 ])\\w*)\\b([a-zA-Z0-9])[a-zA-Z0-9]*\\b") %>%
    unlist %>% 
    paste0(collapse = " ") %>% 
    tolower %>% 
    lemmatize_strings()
}





# file_pipe(): ------------------------------------------------------------

file_pipe <- function(file) {
  file %>% 
    read_csv %>% 
    process_pipe %>% 
    write_csv(file)
}




# process_split_files(): -----------------------------------------------------

process_split_files <- function(dir, cl = detectCores() - 1) {
  file_list <- list.files(dir)
  file_list <- vapply(file_list, function(x) paste0(dir, x), FUN.VALUE = "character")
  pblapply(file_list, file_pipe, cl = cl)
}




# preprocess_data(): ---------------------------------------------------------

preprocess_data <- function(db_export_file) {
  
}




# testing

test_data_raw <- read_csv("../data/product_text/table_export_DATA.csv", n_max = 10000)

test_out <- process_pipeline(test_data_raw)

test_out[43,2]
test_out1[43,2]

hist(test_out$word_count, breaks = 100, xlim = c(0,100))


split_text_file("../data/test/test_chunk.csv", line.count = 10)


file_pipe("../data/test/test_chunk copy.csv")

