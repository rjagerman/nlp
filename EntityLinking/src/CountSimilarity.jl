# NLP Project - Entity Linking
#
# Template
#   Contains the naive entity linking algorithm

using IO
using Util
using ODBC
using Requests
import JSON
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
    dd = Dict{(String, String), Float64}()
    dd[("a", "b")] = 0.9
    a = dd[("a", "b")]
    println(a)
    # Ignore session structure
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)
    ODBC.connect("mynlp")
    # Read tokens and entities
    println("Loading similarity counts data")
    similarity_file = "data/entity-cooccurrence-counts-part-1.gz"
    similarity_file2 = "data/entity-cooccurrence-counts-part-2.gz"
    #similarities = cache("cache/similarities", () -> read_scores(queries, candidates))
    #fill_db_counts(similarity_file2)
    #counts = cache("cache/similarities", () -> read_counts(similarity_file, similarity_file2))

    # Link using a greedy approach with naive candidates
    count = 0
    for query in queries
        if (length(query.annotations) > 0)
          if (length(query.tokens) > 1 && length(query.tokens) < 4) # max length for query
              query.annotations = []
              println(query)
              count = count + 1
              link_single_query(query, candidates)
          end
        end
    end

    # Return all the queries (for scoring)
    return queries

end

function tagme_similarities(firstEntity::String, secondEntity::String)
    queryString = firstEntity * " " * secondEntity
    response = get("http://tagme.di.unipi.it/rel"; query = {"key" => "tagme-NLP-ETH-2015", "tt" => queryString})
    data = JSON.parse(response.data)
    if (data["errors"] == 0)
      return float64(data["result"][1]["rel"])
    else
      return 0
    end
end

function fill_db_counts(similarity_file::String)

    ODBC.connect("mynlp")
    count = 0
    for line in eachline(gzopen(similarity_file))
        line = replace(line, "'", "")
        line = split(line, "\t")
        firstEntity = line[1]
        secondEntity = line[2]
        score = line[3]
        if (int(score) > 20)
          count = count + 1
          if (length(firstEntity) < 100 && length(secondEntity) < 100)
              query_string = "INSERT INTO Similarities (FirstEntity, SecondEntity, Score) VALUES('" * firstEntity * "', '" * secondEntity * "', " * score * ");"
              try
                query(query_string)
              catch
                println(query_string)
              end
          end
        end
    end
    disconnect(conn)

end

function query_db(firstEntity::String, secondEntity::String)
    fe = replace(firstEntity, "'", "")
    se = replace(secondEntity, "'", "")
    result = query("SELECT Score from Similarities WHERE FirstEntity = '" * fe * "' AND SecondEntity = '" * se * "';")
    return result[1, 1]
    #return 0
end

function read_scores(queries, candidates::Function)
    entities = Dict{(String, String), Uint32}()
    for query in queries
        for candidate in candidates(query)
            for firstAnnotation in candidate
                for secondAnnotation in candidate
                    if (firstAnnotation.entity != secondAnnotation.entity)
                        score = 0
                        try
                          score = query_db(firstAnnotation.entity, secondAnnotation.entity)
                        catch
                          nothing
                        end
                        if (score != 0)
                            entities[(firstAnnotation.entity, secondAnnotation.entity)] = score
                        end
                    end
                end
            end
        end
    end
end

##
# Links a single query
#
function link_single_query(query, candidates::Function)

    # Clear previous annotations (e.g. from loading from file)

    # Process all the candidates

    scores = PriorityQueue(Reverse)
    similarities = Dict{(String, String), Float64}()
    for candidate in candidates(query)
        score = 0
        second_score = 0

        # checks for combination of entities
        # need to check all combinations (as it is unclear, which direction is stored in the counts files)
        for firstAnnotation in candidate
            for secondAnnotation in candidate
                if (firstAnnotation.entity != secondAnnotation.entity)
                  sim_score = 0
                  if haskey(similarities, (firstAnnotation.entity, secondAnnotation.entity))
                    sim_score = similarities[(firstAnnotation.entity, secondAnnotation.entity)]
                  elseif haskey(similarities, (secondAnnotation.entity, firstAnnotation.entity))
                    sim_score = similarities[(secondAnnotation.entity, firstAnnotation.entity)]
                  else
                    try
                      sim_score = tagme_similarities(firstAnnotation.entity, secondAnnotation.entity)
                      println(sim_score)
                    catch
                      nothing
                    end
                    similarities[(firstAnnotation.entity, secondAnnotation.entity)] = sim_score
                  end
                  score = score + sim_score
                    #sim_score = 0
                    #if haskey(similarities, (firstAnnotation.entity, secondAnnotation.entity))
                    #    sim_score = 1
                    #elseif haskey(similarities, (secondAnnotation.entity, firstAnnotation.entity))
                    #    sim_score = 1
                    #else
                    #  try
                    #    sim_score = query_db(firstAnnotation.entity, secondAnnotation.entity)
                    #    if (sim_score != 0)
                    #        sim_score = 1
                    #    end
                    #  catch
                    #    nothing
                    #  end
                    #end
                    #  score = score + sim_score
                end
            end
            range = firstAnnotation.range[2] - firstAnnotation.range[1]

            second_score = second_score + firstAnnotation.prior + (100*range)
        end
        # score = score + (10/length(candidate)) + 10*max_range
        # score = score + 1*range_sum
        # probably should take lengths into account (choose ngram with longest annotation)
        # for now chooses the one with the least number of annotations (i.e. annotations itself are longer)
        # -length, as it takes the max
        if !haskey(scores, candidate)
          enqueue!(scores, candidate, (score, second_score))
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
