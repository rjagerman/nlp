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
function link_exhaustive(sessions, model::EntityLinkingModel)

    # Ignore session structure and get all queries in a single array
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)

    # Map each query to its annotated equivalent and return the result
    map(query -> annotate_exhaustive(query, model), queries)
    return queries

end

##
# Annotates the query in a naive greedy approach
#
function annotate_exhaustive(query, candidates::Function)

    # Clear previous annotations (e.g. from loading from file)
    query.annotations = []

    # Get all possible annotation candidates for the query
    annotation_candidates = candidates(query)

    # Create an annotation dictionary, by the starting index of each annotation
    candidates_dict = Dict{Int, Array{Annotation}}()
    while !isempty(annotation_candidates)
        candidate = dequeue!(annotation_candidates)
        push!(get!(candidates_dict, candidate.range[1], Annotation[]), candidate)
    end

    # Perform exhaustive search for the best combination of annotations
    memoscores = [-1.0 for i = 1:length(all_candidates)]
    memoannotations = [Set{Annotation}() for i = 1:length(all_candidates)]
    println("""$(join(query.tokens, " ")) ($(length(all_candidates)) candidates)""")
    #(score, annotations) = find_exhaustive_best(query, Set{Annotation}(), all_candidates, max_depth, memoscore, memoannotations)
    (score, annotations) = find_exhaustive_best(query, 1, candidates_dict, memoscores, memoannotations)

    for candidate in annotations
        push!(query.annotations, candidate)
        println("""  $(candidate)""")
    end
    #query.annotations = annotations

    return query

end

##
# For each index in the query
#   Iterate over all annotations that can be added here
#   When adding them, increase index for the next annotation and call recursively (until end of query tokens)
#   When not adding them, increase index by 1 and call recursively (until end of query tokens)
function find_exhaustive_best(query, current_index, candidates::Dict{Int, Array{Annotation}}, memoscores, memoannotations)
    if current_index > length(memoscores)
        return (0.0, Set{Annotation}())
    end
    if memoscores[current_index] == -1.0 # We have not yet determined the optimal score for this index, compute it:
        best_score = 0.0
        best_annotations = Set{Annotation}()
        for candidate in get!(candidates, current_index, Annotation[])
            # Compute score and annotations when adding candidate
            range = 1 + abs(candidate.range[2] - candidate.range[1])
            (score, annotations) = find_exhaustive_best(query, current_index + range, candidates, memoscores, memoannotations)
            score += candidate.prior
            score -= 0.25 * (length(annotations)+1)
            if score > best_score
                best_score = score
                best_annotations = Set([annotation for annotation in annotations])
                push!(best_annotations, candidate)
            end
        end
        # Do not add any candidate
        (score, annotations) = find_exhaustive_best(query, current_index + 1, candidates, memoscores, memoannotations)
        if score > best_score
            best_score = score
            best_annotations = annotations
        end
        memoscores[current_index] = best_score
        memoannotations[current_index] = best_annotations
    end
    return (memoscores[current_index], memoannotations[current_index])
end
