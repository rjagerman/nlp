# NLP Project - Entity Linking
#
# Greedy
#   Contains the general greedy entity linking algorithm

using IO
using Util
using Base.Collections

##
# Links annotations using a greedy algorithm
# Candidates should return a priority queue with the annotation candidates (most likely one first)
#
function link_greedy(sessions, candidates::Function)

    # Ignore session structure and get all queries in a single array
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)

    # Map each query to its annotated equivalent and return the result
    map(query -> annotate_query(query, candidates), queries)
    return queries

end

##
# Annotates the query in a naive greedy approach
# 
function annotate_query(query, candidates::Function)

    # Clear previous annotations (e.g. from loading from file)
    query.annotations = []

    # Get all annotation candidates for the current ngram size
    annotation_candidates = candidates(query)

    # Candidates are a priority queue (highest scoring one first)
    # Keep adding candidates as long as they don't overlap, starting with the highest scoring one
    while !isempty(annotation_candidates)
        candidate = dequeue!(annotation_candidates)
        if !overlaps(query.annotations, candidate)
            push!(query.annotations, candidate)
        end
    end
    
    return query

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
