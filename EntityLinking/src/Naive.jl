# NLP Project - Entity Linking
#
# Naive
#   Contains the naive entity linking algorithm

using IO
using Util

function link_naive(sessions, scores, tokens, inv_entities)

    # Construct a maximum score lookup dictionary
    # For a given token it should return the highest scoring entity and its score
    max_scores = cache("cache/max_score_dict", () -> max_score_dict(scores, tokens, inv_entities))

    # Ignore session structure and get all queries in a single array
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)

    # Map each query to its annotated equivalent and return the result
    map(query -> annotate_query(query, max_scores), queries)
    return queries

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
# Annotates the query in a naive greedy approach
# 
function annotate_query(query, max_scores)

    # Clear previous annotations (e.g. from loading from file)
    query.annotations = []

    # Start from largest size (greedy)
    for size = length(query.tokens):-1:1

        # Get all annotation candidates for the current ngram size
        candidates = annotation_candidates(query, max_scores, size)

        # Candidates are a priority queue (highest scoring one first)
        # Keep adding candidates as long as they don't overlap, starting with the highest scoring one
        while !isempty(candidates)
            candidate = Collections.dequeue!(candidates)
            if !overlaps(query.annotations, candidate)
                push!(query.annotations, candidate)
            end
        end
    end
    return query

end

##
# Finds all annotation candidates (tokens that match to an entity) for a given ngram size
# 
function annotation_candidates(query, max_scores, size)
    candidates = Collections.PriorityQueue()
    for index = 1:1+(length(query.tokens)-size)
        ngram = join(query.tokens[index:index+size-1], " ")
        if ngram in keys(max_scores)
            annotation = Annotation(max_scores[ngram][2], (index, index+size-1))
            Collections.enqueue!(candidates, annotation, max_scores[ngram][1])
        end
    end
    return candidates
end

##
# Checks if given candidate annotation overlaps with any of the given annotations
# 
function overlaps(annotations::Array{Annotation}, candidate::Annotation)
    for annotation in annotations
        if max(candidate.range[1], annotation.range[1]) <= min(candidate.range[2], annotation.range[2])
            return true
        end
    end
    return false
end
