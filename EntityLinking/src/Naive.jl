# NLP Project - Entity Linking
#
# Naive
#   Contains the naive entity linking algorithm

using IO
using Util
import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse

##
# The naive model
#
type NaiveModel <: EntityLinkingModel
    dictionary::EntityDictionary

    function NaiveModel(crosswiki_file::String)
        dictionary = read_crosswikis(crosswiki_file)
        new(dictionary)
    end
end

##
# Annotates a query using the naive model
#
function annotate!(query::Query, model::NaiveModel)

    # Generate candidates
    candidates = PriorityQueue(Reverse)
    for (range, ngram) in ngrams(query.tokens)
        ngram = strip(lowercase(replace(ngram, r"[^a-z0-9A-Z]+", " ")))
        if ngram in keys(model.dictionary) && !(ngram in Util.stopwords) && !(split(ngram, " ")[1] in Util.stopwords) && !(split(ngram, " ")[end] in Util.stopwords)
            entity = model.dictionary[ngram][1]
            enqueue!(candidates, Annotation(entity.uri, range), (abs(range[2] - range[1]), entity.prior))
        end
    end

    # Add those that don't overlap
    while !isempty(candidates)
        candidate = dequeue!(candidates)
        if !any([overlaps(candidate.range, annotation.range) for annotation in query.annotations])
            push!(query.annotations, candidate)
        end
    end
end
