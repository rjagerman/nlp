# NLP Project - Entity Linking
#
# LDA
#   Get a list of different annotation candidates (entities with position)
#   Compute the probability of seeing the query for all topics: P(q | t) for all t
#   Score all annotation candidates by topical overlap: \sum_t \log P(c | t) + \log P(q | t)
#     Note: We know P(c | t) from our topic modeling predictions of wikipedia pages
#

using DataStructures

##
# The LDA-based entity linking model
#
type LDAModel <: EntityLinkingModel
    dictionary::EntityDictionary
    entity_topics::Dict{String, Array{Float64}} # Maps entities to their topics
    query_topics::Dict{String, Array{Float64}}  # Maps each query to their topics
    query_counter::Int                          # Counter used to keep track of which query we are on

    function LDAModel(crosswiki_file::String, entities_topics_file::String, queries_topics_file::String)
        dictionary = read_crosswikis(crosswiki_file)
        entity_topics = read_topics(entities_topics_file, (entity) -> entity in keys(dictionary))
        query_topics = read_topics(queries_topics_file)
        new(dictionary, entity_topics, query_topics, 1)
    end
end

##
# Annotates a query using the LDA model
#
function annotate!(query::Query, model::LDAModel)

    # Generate candidates where entities have a computed topical overlap
    candidates = PriorityQueue(Reverse)
    for (range, ngram) in ngrams(query.tokens)
        if ngram in keys(model.dictionary)
            for entity in model.dictionary[ngram]

                topical_overlap = 0.0
                if entity in keys(model.entity_topics)
                    topical_overlap = model.entity_topics[entity] ⋅ model.query_topics[model.query_counter]
                end

                score = entity.prior * topical_overlap #P(e) * ||[P(e | t, q) | t \in topics]||
                enqueue!(candidates, Annotation(entity.uri, range), score)
            end
        end
    end

    # Add those that don't overlap, starting with the highest scoring annotation
    while !isempty(candidates)
        candidate = dequeue!(candidates)
        if !any([overlaps(candidate.range, annotation.range) for annotation in query.annotations])
            push!(query.annotations, candidate)
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
