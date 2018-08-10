library(tidyverse)



# read_product_text_table(): -------------------------------------------------



read_product_text_table %>% function(file_path)
{
  read_csv(file_path, na = character()) %>% 
    unite(., text, PRO_NAME:PRO_SHORT_NAME, sep = " ", remove = TRUE)
}






system.time(    
  cleaned <- data %>% mutate(text = map_chr(text ,function(y) {gsub("<[^>]+>", " ", y) %>%  # Remove anything in between brackets
      gsub("[^[:alnum:] ]", " ", .) %>%  # Remove non alpha numeric charachters
      gsub("[0-9]", " ", .) %>% # Remove all numbers
      gsub("(^| ).( |$)", " ", .) %>% # Remove all single characters
      gsub("^ *|(?<= ) | *$", "", ., perl = TRUE) # Replace all multiple spaces with a single space
  }))
)


head(cleaned, n = 13)
nrow(cleaned)

data[12,]
cleaned[12,]


write_lines(cleaned$text, path = paste0("../data/corpus_clean", nrow(cleaned),".txt"))
