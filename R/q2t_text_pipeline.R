library(tidyverse)
library(chunked)

disclaimer <- "While we aim to supply accurate product information it is sourced by manufacturers suppliers and marketplace sellers and has not been provided by Overstock"

# product_text_pipeline(): -------------------------------------------------

product_text_pipeline <- function(product_text, pos)
{
  product_text %>% 
    unite(., text, PRO_NAME:PRO_SHORT_NAME, sep = ". ", remove = TRUE) %>%
    mutate(text = map_chr(text, function(y) {gsub("<[^>]+>", " ", y) %>%  # Remove anything in between brackets
        gsub("[^[:alnum:] ]", " ", .) %>%  # Remove non alpha-numeric characters
        gsub("[0-9]", " ", .) %>% # Remove all numbers
        gsub("(^| ).( |$)", " ", .) %>% # Remove all single characters
        gsub("^ *|(?<= ) | *$", "", ., perl = TRUE) %>%  # Replace all multiple spaces with a single space
        gsub(disclaimer, "", ., fixed = TRUE) %>%  # Removes any instance of the description disclaimer
        gsub("NA", "", ., fixed = TRUE) # Removes all NA words
    }))
}




# chunked_pipeline(): --------------------------------------------------------


io_pipeline <- function(text_file_in, text_file_out)
{
  read_csv(file = text_file_in) %>%
    product_text_pipeline() %>% 
    write_csv(text_file_out)
}


io_pipeline(text_file_in = "../data/product_text/test_chunk.csv", text_file_out = "../data/product_text/corpus_clean_1.csv")


# write_csv(compare, path = "../data/product_text/test_chunk.csv")