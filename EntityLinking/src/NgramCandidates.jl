# NLP Project - Entity Linking
#
# Ngram Candidates
#   Generating all possible ngram candidates

using IO
using Util
using Iterators
using GZip
import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse
include("NgramPartitions.jl")

##
# Parses a single line from the crosswiki dict file and returns a triple
#
function process_line(line::String)
    line = split(line, "\t")
    token = line[1]
    line = split(line[2], " ")
    score = float64(line[1])
    entity = strip(line[2])
    return token, entity, score
end

##
# Reads the top n results of the crosswiki file
#
function read_topn(crosswiki_file, n::Int)
    tokens = Dict{String, Array{(String, Float64)}}()
    last_token = ""
    count = 1
    file = gzopen(crosswiki_file)
    for (token, entity, score) in imap(process_line, filter(line -> length(line) > 0, eachline(file)))
        if token == last_token
            count += 1
        else
            count = 1
        end

        if count <= n
            if !(token in keys(tokens))
                tokens[token] = (String, Float64)[]
            end
            push!(tokens[token], (entity, score))
        end

        last_token = token
    end
    return tokens
end

##
# Find candidates for a given query
# Should return a PriorityQueue of Annotation types
# 
function ngram_candidates(query; n=3, m=4)

    # Construct a candidates priority queue
    candidates = Array(Vector{Annotation}, 0)
    crosswiki_file = "data/crosswikis-dict-preprocessed.gz"
    token_entities = cache("cache/top5", () -> read_topn(crosswiki_file, 5))

    # iterate over query.tokens
    for partition in ngram_partitions(query.tokens, m)
        
        partition_token_candidates = Array(Vector{Annotation}, 0)
        count = 1
        for token in partition
            next_count = count + length(split(token, " "))
            token_candidates = Annotation[]
            if token in keys(token_entities)
                for (entity, score) in token_entities[token]
                    push!(token_candidates, Annotation(entity, (count, next_count - 1)))
                end
            end
            if !isempty(token_candidates)
                push!(partition_token_candidates, token_candidates)
            end
            count = next_count
        end
        if !isempty(partition_token_candidates)
            for combination in apply(Iterators.product, partition_token_candidates)
                push!(candidates, [combination...])
            end
        end

    end

    # Return stuff
    return candidates

end
