# NLP Project - Entity Linking
#
# Naive
#   Contains the naive entity linking algorithm

using IO
using Util
import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse

##
# Links using the naive algorithm
#
function link_naive(sessions)

    # Read tokens and entities
    println("Loading crosswiki data")
    crosswiki_file = "data/crosswikis-dict-preprocessed.gz"
    tokens, entities, scores = cache("cache/crosswikis", () -> read_dict(crosswiki_file))

    # Generate the inverse index
    inv_tokens = {index => token for (token, index) in tokens}
    inv_entities = {index => entity for (entity, index) in entities}

    # Construct a maximum score lookup dictionary
    # For a given token it should return the highest scoring entity and its score
    max_scores = cache("cache/max_score_dict", () -> max_score_dict(scores, tokens, inv_entities))

    # Link using a greedy approach with naive candidates
    return link_greedy(sessions, (query) -> naive_candidates(query, max_scores))

end

##
# Computes a dictionary, mapping each unique token to the highest scoring entity and its score
# 
function max_score_dict(scores, tokens, inv_entities)
    max_scores = Dict{String, (Float64, String)}()
    for (token, index) in tokens
        token_scores = scores[:, index]
        if nnz(token_scores) > 0 # nnz check required to prevent sparse matrix bug 10407
            (score, entity_index) = findmax(token_scores)
            max_scores[token] = (score, inv_entities[entity_index])
        end
    end
    return max_scores
end

##
# Finds all annotation candidates (tokens that match to an entity) for a given ngram size
# 
function naive_candidates(query, max_scores)

    # Construct a candidates priority queue
    candidates = PriorityQueue(Reverse)

    # Iterate over all possible ngram sizes
    for size = 1:length(query.tokens)

        # Iterate over all tokens of this size
        for index = 1:1+(length(query.tokens)-size)

            # Grab the ngram and compute its score and add it to the priority queue
            ngram = join(query.tokens[index:index+size-1], " ")
            if ngram in keys(max_scores)
                annotation = Annotation(max_scores[ngram][2], (index, index+size-1))
                enqueue!(candidates, annotation, (size, max_scores[ngram][1]))
            end

        end
    end

    return candidates

end
