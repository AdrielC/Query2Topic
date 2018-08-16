disclaimer <- "While we aim to supply accurate product information it is sourced by manufacturers suppliers and marketplace sellers and has not been provided by Overstock"
disclaimer2 <- "While we aim to supply accurate product information, it is sourced by manufacturers, suppliers and marketplace sellers, and has not been provided by Overstock"

# split_text_file(): ------------------------------------------------------
### Only works on a Unix system with coreutils installed
### If function fails with split function, try removing the g suffix from gsplit.

split_text_file <- function(in.file.path, line.count = 10000) {
  if(!file.exists(in.file.path)) {
    stop(paste("File:", in.file.path, "could not be found"))
  }
  
  filepath <- str_extract(in.file.path, ".*\\/")
  filename <- str_extract(in.file.path, "([^\\/]+)$")
  fileid <- str_extract(in.file.path, "[ \\w-]+?(?=\\.)")
  
  system(
    paste0(
      paste0("perl -e '$/=\"\"; while(<>){ $_ =~ s/\\n(?!\\b\\d*,\\b)/$1 /g; print; }' ", in.file.path, " > ", filepath, "tmp.csv", " && "),
      paste0("cd ", filepath, " && mkdir ", fileid, " && cd ", fileid), " && ", 
      "tail -n +2 ../tmp.csv", " | gsplit -l ", line.count, " - split_
      for file in split_*
        do
      head -n 1 ../tmp.csv", " > tmp_file
      cat $file >> tmp_file
      mv -f tmp_file $file
      done"
    )
  )
  
  system(paste0("rm ", filepath, "tmp.csv"))
  
  dir <- paste0(filepath, fileid, "/")
  return(dir)
}


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
  return(dir)
}


# merge_csv(): ------------------------------------------------------------

merge_csv <- function(dir, out_file) {
  system(
    paste0(
      "OutFileName='", out_file, "'
      i=0
      for filename in ", dir, "*; do
        if [ '$filename'  != '$OutFileName' ] ;
        then
          if [[ $i -eq 0 ]] ; then
            head -1  $filename >   $OutFileName
          fi
          tail -n +2  $filename >>  $OutFileName
          i=$(( $i + 1 ))
        fi
      done"
    )
  )
}


# preprocess_data(): ---------------------------------------------------------

preprocess_data <- function(db_export_file, out_file, ...) {
  db_export_file %>% 
    split_text_file(...) %>% 
    process_split_files() %>% 
    merge_csv(out_file)
}







# testing -----------------------------------------------------------------
# 
# preprocess_data("../data/product_text/table_export_DATA_utf.csv", "../data/processed_corps/clean_full.txt", line.count = 10000)
# 
# preprocess_data("../data/test/test_chunk_utf.csv", "../data/test/test_out.csv", line.count = 2)

# 
