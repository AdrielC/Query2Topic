library(stringr)
library(chunked)
library(tidyverse)
library(reticulate)
library(pbapply)
library(parallel)

test <- "['king size beds','Upholstered platform bed','Upholstered platform king bed']"
test2 <- "warehouse 718738 columbia forest products 2717 red rock brown 9 ft. 6 in. x 13 ft. 6 in. indoor area rug momeni behr premium plus 534005 good directions 1971p"

# chunked_pipeline -------------------------------------------------------- 

csv_pipeline <- function(in_file)
{
  read_csv(in_file, progress = TRUE) %>%
    text_process_pipe()
}


# text_process_pipe --------------------------------------------------------

extract_from_brack <- function(x)
{
  paste(unlist(str_extract_all(string = x, pattern = "(?!,)(?<=')[^']+(?=')")), collapse = " ")
}

clean_text <- function(text)
{ 
  paste0(
    unlist(
      str_extract_all(text
                      , "(?!(\\bin\\b)|(\\bx\\b)|(\\bft\\b)|(\\b[a-zA-Z]{1}\\b)|[^A-Za-z]\\w*|(\\w*[^A-Za-z \\n])|(?<=[^a-zA-Z ])\\w*)\\b([a-zA-Z])[a-zA-Z]*\\b"
      )), collapse = " ")
}

text_process_pipe <- function(data_in)
{
  data_in %>% 
    select(hp_search_phrases) %>% 
    mutate(hp_search_phrases = map_chr(hp_search_phrases, extract_from_brack)) %>% 
    mutate(hp_search_phrases = map_chr(hp_search_phrases, clean_text)) %>% 
    mutate(hp_search_phrases = tolower(hp_search_phrases))
}

dir <- "data/pre_processed/"
file_list <- list.files(dir)
file_list <- vapply(file_list, function(x) paste0(dir, x), FUN.VALUE = "character")
cl <- detectCores()
system.time(
  data <- pblapply(file_list, csv_pipeline, cl = cl)
)
data <- bind_rows(data)

write_delim(data, "data/processed/out2.txt", "\n", col_names = FALSE)


# for(file in 1:length(list.files("data/pre_processed/"))){
#   if(file == 1){
#     data <- read_csv(paste0("data/pre_processed/", file, ".csv")) %>% 
#       text_process_pipe()
#   } else {
#     tmp <- read_csv(paste0("data/pre_processed/", file, ".csv")) %>% 
#       text_process_pipe()
#     data <- bind_rows(data, tmp)
#   }
#   print(file)
# }