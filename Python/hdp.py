def create_dict(corpus_file_path):
    dictionary = corpora.Dictionary(line.lower().split() for line in open(corpus_file_path))
    return dictionary


def get_filter_ids(filter_word_set, dictionary):
    filter_set_ids = [dictionary.token2id[filter_word] for filter_word in filter_word_set
                      if filter_word in dictionary.token2id]
    return filter_set_ids


def save_object(obj, filename):
    with open(filename, 'wb') as output:  # Overwrites any existing file.
        pickle.dump(obj, output, pickle.HIGHEST_PROTOCOL)


def load_object():
    with open(filename, 'rb') as input:
        return pickle.load(input)


def cutoff_mod(model, alpha_cutoff_value, scale_beta=False):
    lda_beta = model.lda_beta
    lda_alpha = model.lda_alpha
    cutoff_idx = np.array(list(map(lambda x: x > alpha_cutoff_value, lda_alpha)))
    if scale_beta == True:
        lda_beta = np.apply_along_axis(lambda values: (values - values.min()) / (values - values.min()).sum(), 0, lda_beta)
    model.lda_beta = lda_beta[cutoff_idx]
    model.lda_alpha = lda_alpha[cutoff_idx]
    return model


class MyCorpus(object):
    def __init__(self, corpus_file_path):
        self.corpus_file_path = corpus_file_path
        self.dict = create_dict(corpus_file_path)
        self.filtered_tokens = set({}) # This can be used later when creating a sub-hpd
        self.hdp_models = {} # This is where each model will live for the current corpus

    def __iter__(self):
        for line in open(self.corpus_file_path):
            yield self.dict.doc2bow(line.lower().split()) # assume there's one document per line, tokens separated by whitespace

    def __len__(self):
        return len(list(iter(self)))

    def get_texts(self, limit=None):
        if limit is None:
            limit = len(self)

        for lim_idx, line in enumerate(open(self.corpus_file_path)):
            if lim_idx < limit:
                yield line.lower().split()

    def remove_words(self, *filter_word_sets):
        for filter_word_set in filter_word_sets:
            if not isinstance(filter_word_set, (set, frozenset)): # type check
                sys.exit("Filter word set must by of type set or frozenset")
            filter_set_ids = get_filter_ids(filter_word_set, dictionary = self.dict)
            self.filtered_tokens.add(filter_word_set) # Record which tokens were removed from the current corpus instance
            self.dict.filter_tokens(filter_set_ids) # remove the tokens by the id
            self.dict.compactify() # remove the gaps in the dictionary left from the filter step

    def get_new_doc_id(self, doc):
        doc_id = self.dict.doc2bow(doc.lower().split())
        return doc_id

    def run_hdp(self, model_id, cutoff = -1, scale_beta = False, **kwargs):
        print(kwargs)
        start_time = time.time()
        hdp_model = HdpModel(self, self.dict, **kwargs)
        runtime = time.time() - start_time
        print("--- %s seconds ---" % runtime)
        if cutoff > 0:
            print("Truncating topics to beta values above %s" % cutoff)
            hdp_model = cutoff_mod(hdp_model, alpha_cutoff_value = cutoff, scale_beta = scale_beta)
        self.hdp_models[model_id] = {'model':hdp_model, 'args':kwargs, 'runtime':runtime}

    def get_new_doc_topics(self, doc, *model_ids):
        if model_ids:
            topics_out = {}
            for model_id in model_ids:
                doc2id = self.get_new_doc_id(doc)
                topic_distribution = self.hdp_models[model_id]['model'][doc2id]
                topics_out[model_id] = topic_distribution
            return topics_out
        else:
            print('Please supply one or more model ids to calculate topic distributions for a new document')


def evaluate_graph(dictionary, corpus, texts, limit):
    """
    Function to display num_topics - LDA graph using c_v coherence

    Parameters:
    ----------
    dictionary : Gensim dictionary
    corpus : Gensim corpus
    limit : topic limit

    Returns:
    -------
    lm_list : List of LDA topic models
    c_v : Coherence values corresponding to the LDA model with respective number of topics
    """
    c_v = []
    lm_list = []
    for num_topics in range(1, limit):
        lm = LdaModel(corpus=corpus, num_topics=num_topics, id2word=dictionary)
        lm_list.append(lm)
        cm = CoherenceModel(model=lm, texts=texts, dictionary=dictionary, coherence='c_v')
        c_v.append(cm.get_coherence())

    # Show graph
    x = range(1, limit)
    plt.plot(x, c_v)
    plt.xlabel("num_topics")
    plt.ylabel("Coherence score")
    plt.legend(("c_v"), loc='best')
    plt.show()

    return lm_list, c_v
