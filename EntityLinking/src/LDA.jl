# NLP Project - Entity Linking
#
# LDA
#   Get the candidates provided by our heuristics
#   Compute topics(q) for query q and topics(e) for candidate entity e
#   This results in a distance score between query and entity: cosine_dist(topics(q), topics(e))
#   We remove candidate annotations that have a large cosine_dist (using cutoff_threshold)
#   For those that are removed we attempt to find a replacement that has a small cosine_dist (using dropin_threshold)
#

using Distances

##
# The LDA-based entity linking model
#
type LDAModel <: EntityLinkingModel
    dictionary::EntityDictionary
    entity_topics::Dict{String, Array{Float64}} # Maps entities to their topics
    query_topics::Dict{String, Array{Float64}}  # Maps queries to their topics
    query_counter::Int                          # Counter used to keep track of which query we are on
    cutoff_threshold::Float64                   # Threshold at which to remove entities (cosine distance from query)
    dropin_threshold::Float64                   # Threshold at which to drop in replacements

    function LDAModel(crosswiki_file::String, entities_topics_file::String, queries_topics_file::String)
        dictionary = read_crosswikis(crosswiki_file)

        # Create a set of all possible entities
        all_entities = Set{String}()
        for (token, entities) in dictionary
            for entity in entities
                push!(all_entities, entity.uri)
            end
        end

        entity_topics = cache("cache/entity.topics", () -> read_topics(entities_topics_file, filter = (entity) -> entity in all_entities))
        query_topics = read_topics(queries_topics_file)

        new(dictionary, entity_topics, query_topics, 1, 0.95, 0.2)
    end
end

##
# Annotates a query using the LDA model
#
function annotate!(query::Query, model::LDAModel)

    candidates = PriorityQueue(Reverse)
    for (range, ngram) in ngrams(query.tokens)
        ngram = strip(lowercase(replace(ngram, r"[^a-z0-9A-Z]+", " ")))
        if ngram in keys(model.dictionary) && !(ngram in Util.stopwords) && !(split(ngram, " ")[1] in Util.stopwords) && !(split(ngram, " ")[end] in Util.stopwords)
            entity = model.dictionary[ngram][1]
            distance = 0.0
            if entity.uri in keys(model.entity_topics)
                distance = cosine_dist(model.entity_topics[entity.uri], model.query_topics[string(model.query_counter)])
            end
            enqueue!(candidates, Annotation(entity.uri, range, distance), (abs(range[2] - range[1]), entity.prior))
        end
    end

    # Add those that don't overlap, starting with the highest scoring annotation
    while !isempty(candidates)
        candidate = dequeue!(candidates)
        if !any([overlaps(candidate.range, annotation.range) for annotation in query.annotations])
            if candidate.prior < model.cutoff_threshold
                push!(query.annotations, candidate)
            else
                # Find a replacement
                ngram = join(query.tokens[candidate.range[1]:candidate.range[2]], " ")
                ngram = strip(lowercase(replace(ngram, r"[^a-z0-9A-Z]+", " ")))
                if ngram in keys(model.dictionary)
                    min_distance = 1.0
                    replacement = candidate.entity
                    for entity in model.dictionary[ngram][1:min(8, length(model.dictionary[ngram]))]
                        if entity.uri in keys(model.entity_topics)
                            distance = cosine_dist(model.entity_topics[entity.uri], model.query_topics[string(model.query_counter)])
                            if distance < min_distance
                                min_distance = distance
                                replacement = entity.uri
                            end
                        end
                    end
                    if min_distance < model.dropin_threshold
                        candidate.entity = replacement
                        push!(query.annotations, candidate)
                    end
                end
            end
        end
    end

    model.query_counter += 1
end

##
# Reads the topics from given file
# A filter function can be provided to filter out certain predictions
#
function read_topics(file::String; filter::Function = (x) -> true)
    result = Dict{String, Array{Float64}}()
    for line in eachline(open(file))
        features = split(line)
        entity = features[end]
        if filter(entity)
            topics = map(float64, features[1:end-1])
            result[entity] = topics / sum(topics)
        end
    end
    result
end
