# NLP Project - Entity Linking
#
# Tagme
#   Contains the tagme entity linking API

using IO
using Util
using Requests
import JSON
import Base.Collections: PriorityQueue, enqueue!
import Base.Order: Reverse

##
# The tagme model
#
type TagmeModel <: EntityLinkingModel
    api_key::String
    ɛ::Float64
    TagmeModel(api_key) = new(api_key, 0.3)
    TagmeModel(api_key, ɛ) = new(api_key, ɛ)
end

##
# Annotates a query using the naive model
#
function annotate!(query::Query, model::TagmeModel)
    println("""Annotating query: $(join(query.tokens, " "))""")

    # Get annotation candidates from tagme API
    response = get("http://tagme.di.unipi.it/tag"; query = {"epsilon" => model.ɛ, "key" => model.api_key, "text" => join(query.tokens, " ")})
    data = JSON.parse(response.data)
    mapping = character_map(query)
    candidates = PriorityQueue(Reverse)
    for annotation in data["annotations"]
        range = (mapping[annotation["start"]], mapping[annotation["end"]])
        a = Annotation(replace(annotation["title"], " ", "_"), range)
        if !(a in keys(candidates)) # Prevent duplicate entities (facebook.com and facebook)
            enqueue!(candidates, a, (abs(range[1] - range[2]), annotation["rho"])) # Sort on length first, then on rho
        end
    end

    # Add annotations, only if they don't overlap
    while !isempty(candidates)
        candidate = dequeue!(candidates)
        if !any([overlaps(candidate.range, annotation.range) for annotation in query.annotations])
            push!(query.annotations, candidate)
        end
    end
end

##
# Creates a mapping from character indices to token indices
#
function character_map(query::Query)
    mapping = Dict{Int, Int}()
    current_index = 0
    for (token_index, token) in enumerate(query.tokens)
        for i = current_index:current_index+length(token)
            mapping[i] = token_index
        end
        current_index += length(token) + 1
    end
    return mapping
end
