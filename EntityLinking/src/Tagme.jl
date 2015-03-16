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
# Links using the tagme algorithm as annotation candidates
#
function link_tagme(sessions)
    return link_greedy(sessions, tagme_candidates)
end

##
# Generates a priority queue of annotation candidates in a query
#
function tagme_candidates(query)
    println("Annotating " * join(query.tokens, " "))

    # Send HTTP request and parse HTML
    response = get("http://tagme.di.unipi.it/tag"; query = {"epsilon" => 0.3, "key" => "tagme-NLP-ETH-2015", "text" => join(query.tokens, " ")})
    data = JSON.parse(response.data)
    mapping = character_map(query)

    # Construct candidates priority queue
    candidates = PriorityQueue(Reverse)

    # Add all provided annotations to the priority queue with scoring based on length and rho
    for annotation in data["annotations"]
        range = (mapping[annotation["start"]], mapping[annotation["end"]])
        a = Annotation(replace(annotation["title"], " ", "_"), range)
        if !(a in keys(candidates)) # Prevent duplicate entities (facebook.com and facebook)
            enqueue!(candidates, a, (abs(range[1] - range[2]), annotation["rho"])) # Sort on length first, then on rho
        end
    end
    return candidates
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

