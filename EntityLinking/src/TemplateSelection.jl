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
function link_template(sessions, candidates::Function)

    # Ignore session structure
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)

    # Link using a greedy approach with naive candidates
    for query in queries
        link_single_query(query, candidates)
    end

    # Return all the queries (for scoring)
    return queries

end

##
# Links a single query
#
function link_single_query(query, candidates::Function)

    # Clear previous annotations (e.g. from loading from file)
    query.annotations = []

    # Process all the candidates
    for candidate in candidates(query)
        # Process this candidate:
        # Do we add it or not to the query?


        # Add an annotation like this:
        # push!(query.annotations, candidate)

    end

end
