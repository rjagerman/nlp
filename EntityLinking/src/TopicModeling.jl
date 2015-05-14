# NLP Project - Entity Linking
#
# Topic modeling
#   Get a list of different annotation candidates (entities with position)
#   Compute the probability of seeing the query for all topics: P(q | t) for all t
#   Score all annotation candidates by topical overlap: \sum_t \log P(c | t) + \log P(q | t)
#     Note: We know P(c | t) from our topic modeling predictions of wikipedia pages
#   Keep selecting top annotation as long as they don't overlap
#   Optional: Use some heuristic for also scoring length of annotation
#

using IO
using Util
import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse

topic_query_index = 1

##
# Links using the naive algorithm
#
function link_topics(sessions; α=0.5, β=0.1, γ=0.4, threshold=0.0005, n=15)

    global topic_query_index

    # Read data for token->entity and entity->topic_distribution
    token_entities = deserialize(open("data/dictionary-top5000.dat"))
    entity_topics = deserialize(open("data/entity-topics-filtered.dat"))

    # Flat map queries, and send them to VW while obtaining results
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)
    query_topics = cache("cache/querylda-$(length(queries)).results", () -> vw_results(queries))

    # Link using a greedy approach with naive candidates
    topic_query_index = 1
    return link_greedy(sessions, (query) -> topical_candidates(query, query_topics, token_entities, entity_topics, threshold, α, β, γ))

end

##
# Runs all queries through VW and returns the topic distributions
#
function vw_results(queries)

    google_queries = cache("cache/googleresults-$(length(queries)).dat", () -> googlesearch(queries))
    google_queries["processed"]

    open(`vw -t -i data/lda.fmodel -p cache/lda.predictions`, "w") do io
        count = 0
        for query in queries
            #output_features = string2bow(join(query.tokens, " "))
            count += 1
            output_features = string2bow(join(google_queries["processed"][count], " "))
            write(io, "id" * string(count) * "| ")
            for feature in keys(output_features)
                write(io, feature * ":" * string(output_features[feature]) * " ")
            end
            if length(output_features) == 0
                write(io, "1:1.0")
            end
            write(io, "\n")
        end
        close(io)
    end
    output = Array[]
    for line in eachline(open("cache/lda.predictions", "r"))
        features = split(line)
        topics = map(float64, features[1:end-1])
        topics = topics ./ sum(topics)
        push!(output, topics)
    end
    return output
end

##
# Finds all annotation candidates (tokens that match to an entity) for a given ngram size
#
function topical_candidates(query, query_topics, entities, entity_topics, threshold, α, β, γ)

    global topic_query_index

    # Construct a candidates priority queue
    candidates = PriorityQueue(Reverse)

    # Iterate over all possible ngram sizes
    for size = 1:length(query.tokens)

        # Iterate over all tokens of this size
        for index = 1:1+(length(query.tokens)-size)

            # Grab the ngram and compute its score and add it to the priority queue
            ngram = lowercase(replace(join(query.tokens[index:index+size-1], " "), r"[^a-z0-9 ]+", ""))
            if ngram in keys(entities)
                max_score = 0.0
                for (entity, prior) in entities[ngram]
                    query_topic = query_topics[topic_query_index]
                    score = β * prior + (γ * size)
                    score *= 1.0 / (0.1 * log(length(entities[ngram])))
                    if entity in keys(entity_topics)
                        entity_topic = entity_topics[entity]
                        score += α * (query_topic ⋅ entity_topic)
                    end
                    split(lowercase(entity), "_")
                    contains(lowercase(join(query.tokens, " ")), )
                    if join(query.tokens, " ") == "2005 presidential election in Egypt"
                        println(join(query.tokens, " ") * " [$(ngram)] <-> $(entity) = $(score)")
                    end
                    annotation = Annotation(entity, (index, index+size-1))
                    if !(annotation in keys(candidates))
                        enqueue!(candidates, annotation, score)
                    end
                end
            end

        end
    end

    topic_query_index += 1
    return candidates

end

function topics_of_query(query, entities, entity_topics)

    topics = Array[]

    # Iterate over all possible ngram sizes
    for size = 1:length(query.tokens)

        # Iterate over all tokens of this size
        for index = 1:1+(length(query.tokens)-size)

            # Grab the ngram and compute its score and add it to the priority queue
            ngram = lowercase(join(query.tokens[index:index+size-1], " "))
            if ngram in keys(entities)
                for (entity, prior) in entities[ngram]
                    if entity in keys(entity_topics)
                        entity_topic = entity_topics[entity]
                        push!(topics, entity_topic)
                    else
                        println("Unknown entity $(entity)")
                    end
                end
            end

        end
    end
    if length(topics) > 0
        return mean(topics)
    else
        return [1.0 for i = 1:30]
    end
end
