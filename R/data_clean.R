library(tidyverse)


data <- read_csv("../data/table_export_DATA.csv", na = character()) %>% 
  unite(., text, PRO_NAME:PRO_SHORT_NAME, sep = " ", remove = TRUE)

nrow(data)

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
