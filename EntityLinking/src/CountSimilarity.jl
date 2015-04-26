# NLP Project - Entity Linking
#
# Template
#   Contains the naive entity linking algorithm

using IO
using Util
import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse

##
# Entity Linking example
#
# Typical usage with a candidates function:
#   ...
#   my_annotated_queries = link_template(sessions, some_candidate_function)
#   ...
#
function link_counts(sessions, candidates::Function)

    # Ignore session structure
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)

    # Read tokens and entities
    println("Loading similarity counts data")
    similarity_file = "data/entity-cooccurrence-counts-part-1.gz"
    similarity_file2 = "data/entity-cooccurrence-counts-part-2.gz"
    counts = cache("cache/similarities", () -> read_counts(similarity_file, similarity_file2))

    # Link using a greedy approach with naive candidates
    for query in queries
        if (length(query.tokens) < 5) # max length for query
            link_single_query(query, counts, candidates)
        end
    end

    # Return all the queries (for scoring)
    return queries

end

##
# Links a single query
#
function link_single_query(query, counts, candidates::Function)

    # Clear previous annotations (e.g. from loading from file)
    query.annotations = []

    # Process all the candidates
    println(query)
    scores = PriorityQueue(Reverse)

    for candidate in candidates(query)
        score = 0
        # checks for combination of entities
        # need to check all combinations (as it is unclear, which direction is stored in the counts files)
        if (length(candidate) == 1)
            score = 10 + candidate[1].prior
        else
            for firstAnnotation in candidate
                for secondAnnotation in candidate
                    if (firstAnnotation.entity != secondAnnotation.entity)
                      # function to get value or return 0 by default
                      # score based on sum of scores (should also try out average etc.)
                        if haskey(counts, (firstAnnotation.entity, secondAnnotation.entity))
                            score = score + counts[(firstAnnotation.entity, secondAnnotation.entity)]
                        end
                    end
                end
                score = score + firstAnnotation.prior
            end
        end
        # probably should take lengths into account (choose ngram with longest annotation)
        # for now chooses the one with the least number of annotations (i.e. annotations itself are longer)
        # -length, as it takes the max
        if !haskey(scores, candidate)
          enqueue!(scores, candidate, (score, -length(candidate)))
        end
    end
    if (!isempty(scores))
        # Select the highest scoring candidate as the query.annotations
        best_annotations = peek(scores)[1]
         println(peek(scores))
        for annotation in best_annotations
            push!(query.annotations, annotation)
        end
    end
end