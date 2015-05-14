# NLP Project - Entity Linking
#
# Probabilistic
#   Get a list of different annotation candidates (entities with position)
#   Compute the probability of seeing the query terms in the candidate entity wikipedia page:
#   P(e) = \sum_{t \in q} \log P(t | e)
#     Note: We know P(t | e) from a simple bag-of-words model of the wikipedia pages
#   Keep selecting top annotation as long as they don't overlap
#   Optional: Use some heuristic for also scoring length of annotation
#

using IO
using Util
using GZip
using JSON
import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse

query_topic_index = 0

type ProbabilisticModel <: EntityLinkingModel
    α::Float64 # Weight of the prior
    β::Float64 # Weight of the topical overlap (query <-> entity)
    γ::Float64 # Weight of the probability P(entity | query) = \prod_{t \in query} P(t | entity)  (with smoothing)
    δ::Float64 # Weight of the annotation range
    threshold::Float64 # Cutoff threshold (relative to maximum annotation score)
    dictionary::EntityDictionary # Entity dictionary, mapping tokens to possible entities (with priors)
    wikipedia::Dict{String, String} # Plaintext wikipedia articles by entity name (to compute P(entity | query))

    ProbabilisticModel(α::Float64, β::Float64, γ::Float64, δ::Float64, threshold::Float64) =
        new(α, β, γ, δ, threshold, dictionary::EntityDictionary, wikipedia::Dict{String, String})
end



##
# Links using a probabilistic topic modeling approach
#
function link_probabilistic(sessions; α=0.35, β=0.2, γ=0.65, δ=0.5, threshold=0.3)

    global query_topic_index

    # Read data for token->entity and entity->topic_distribution
    token_entities = deserialize(open("data/dictionary/top5000.dat"))
    entity_topics = deserialize(open("data/lda/filtered.predictions"))

    # Read (reduced) wikipedia plaintext articles
    wikipedia = cache("cache/plaintextwiki.dat", () -> wikipedia_plaintext(token_entities))

    # Flat map queries, and send them to VW for LDA topic modeling while obtaining results
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)
    query_topics = cache("cache/query-lda100-$(length(queries)).results", () -> vw_results(queries))

    # Link using a greedy approach with naive candidates
    #println("Linking entities")
    query_topic_index = 0
    return link_exhaustive(sessions, (query) -> probabilistic_candidates(query, token_entities, wikipedia, entity_topics, query_topics, α, β, γ, δ, threshold))

end

##
# Finds all annotation candidates (tokens that match to an entity) for a given ngram size
#
function probabilistic_candidates(query, entities, wikipedia, entity_topics, query_topics, α, β, γ, δ, threshold)

    global query_topic_index
    query_topic_index += 1

    # Construct a candidates priority queue
    candidates = PriorityQueue(Reverse)

    # Iterate over all possible ngrams
    map!(clean, query.tokens)
    patterns = map(Regex, filter(x -> x in Util.stopwords, query.tokens))
    for ngram in iterate_ngrams(query.tokens)
        if ngram in keys(entities)
            for (entity, prior) in entities[ngram]
                score = α * prior
                if entity in keys(wikipedia)
                    for token in patterns
                        score += γ * length(matchall(token, wikipedia[entity])) / length(wikipedia[entity])
                    end
                end
                if entity in keys(entity_topics)
                    score += β * (query_topics[query_topic_index] ⋅ entity_topics[entity])
                end
                score += δ * size
                annotation = Annotation(entity, (index, index+size-1), float16(score))
                if !(annotation in keys(candidates))
                    enqueue!(candidates, annotation, score)
                end
            end
        end
    end

    return candidates
end

##
# Constructs a filtered "plaintext" wikipedia with which we can check word-entity probabilities
#
function wikipedia_plaintext(dictionary)

    # Entities
    entities = Set{String}()
    for (token, entity_list) in dictionary
        for (entity, prior) in entity_list
            push!(entities, entity)
        end
    end

    # Construct text
    output = Dict{String, String}()
    count = 0
    for line in eachline(gzopen("data/enwiki.txt.gz"))
        count += 1
        obj = JSON.parse(line)
        entity = obj["url"][length("http://en.wikipedia.org/wiki/")+1:end]
        if entity in entities
            output[entity] = replace(obj["text"], r"[^a-zA-Z0-9]+", " ")
        end
        if count % 1000 == 0
            println(count)
        end
    end
    return output

end



##
# Runs all queries through VW and returns the topic distributions
#
function vw_results(queries)

    google_queries = cache("cache/googleresults-$(length(queries)).dat", () -> googlesearch(queries))
    google_queries["processed"]

    open(`vw -t -i data/lda/model.f -p cache/lda.predictions`, "w") do io
        count = 0
        for query in queries
            #output_features = string2bow(join(query.tokens, " "))
            count += 1
            output_features = string2bow((join(query.tokens, " ") * " ")^3 * join(google_queries["processed"][count], " "))
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
