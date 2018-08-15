library(tidyverse)
library(stringr)
library(pbapply)
library(parallel)
library(textstem)
library(tm)
source("func.R")
source("filterset.R")

remove_words <- function(text, remove_words) {
  removeWords(text, remove_words) %>% 
    str_trim() %>% 
    gsub("\\s+", " ", x = .)
}

data_in <- read_csv("../data/test/test_out_full.csv")

data_filter <- 
  data_in %>% 
  filter(word_count > 60) %>% 
  select(text) %>% 
  sample_n(10000) %>% 
  mutate(text = remove_words(text, filterset)) %>% 
  mutate(word_count = str_count(text, pattern = '\\w+')) %>% 
  filter(word_count > 30)

hist(data_filter$word_count, breaks = 30, xlim = c(0, 250))



write_delim(data_filter, path = "../data/product_text/corpus_clean_3_10g_sample.dat", delim = "\n", col_names = FALSE)

data_filter %>% 
  filter(word_count > 200) %>% 
  sample_n(1)
