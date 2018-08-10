from gensim.test.utils import common_corpus, common_dictionary, datapath, get_tmpfile, common_texts
from gensim.models import HdpModel
from gensim.corpora import MalletCorpus
from gensim.corpora import Dictionary
from gensim import corpora
from six import iteritems # collect statistics about all tokens
import numpy as np
import pandas as pd
import sys

# import sets of words to remove
from gensim.parsing.preprocessing import remove_stopwords, STOPWORDS
from OSTK_STOPWORDS import DESCRIPTIVE_WORDS




def create_dict(corpus_file_path):
    dictionary = corpora.Dictionary(line.lower().split() for line in open(corpus_file_path))
    return dictionary


def get_filter_ids(filter_word_set, dictionary):
    filter_set_ids = [dictionary.token2id[filter_word] for filter_word in filter_word_set
                      if filter_word in dictionary.token2id]
    return filter_set_ids

class hHdpModel(object):
    def __init__(self, corpus_file_path):
        pass


class MyCorpus(object):
    def __init__(self, corpus_file_path):
        self.corpusFilepPath = corpus_file_path
        self.dict = create_dict(corpus_file_path)
        self.filteredTokens = set({}) # This can be used later when creating a sub-hpd
        self.hdpModels = [] # This is where each model will live for the current corpus

    def __iter__(self):
        for line in open(self.corpusFilepPath):
            yield self.dict.doc2bow(line.lower().split()) # assume there's one document per line, tokens separated by whitespace

    def __len__(self):
        return len(list(iter(self)))

    def remove_words(self, *filter_word_sets):
        for filter_word_set in filter_word_sets:
            if not isinstance(filter_word_set, (set, frozenset)): # type check
                sys.exit("Filter word set must by of type set or frozenset")
            filter_set_ids = get_filter_ids(filter_word_set, dictionary = self.dict)
            self.filteredTokens.add(filter_word_set) # Record which tokens were removed from the current corpus instance
            self.dict.filter_tokens(filter_set_ids) # remove the tokens by the id
            self.dict.compactify() # remove the gaps in the dictionary left from the filter step

    def get_new_doc_id(self, doc):
        doc_id = self.dict.doc2bow(doc.lower().split())
        return doc_id

    def run_hdp(self, modelId, **kwargs):
        print(kwargs)
        hdpModel = HdpModel(self, self.dict, kwargs)
        hdpData = {modelId:
                   {'model':hdpModel,
                    'args':kwargs}}

        self.hdpModels.append(hdpData)

    def get_new_doc_topics(self, doc, *modelIds):
        for modelId in modelIds:
            doc_ids = []
            doc_ids.append(self.hdpModels[modelid]['model'][self.get_new_doc_id(doc)])
            return doc_ids

def main():
    # Create the corpus
    hundoGrandoCorpus = MyCorpus("../data/corpus_clean100000.txt")
    # Remove words
    hundoGrandoCorpus.remove_words(STOPWORDS, DESCRIPTIVE_WORDS)
    hundoGrandoCorpus.dict.filter_extremes(no_below=1)
    hundoGrandoCorpus.dict.compactify()

    hundoGrandoCorpus.run_hdp(modelId='testMod',chunksize=1000, max_time=100, K = 4, T = 10000, alpha=10, gamma=1, scale=1, eta=0.5)


if __name__ == '__main__':
    main()
