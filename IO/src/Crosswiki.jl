# NLP Project - Entity Linking
#
# IO.Crosswiki
#   Contains various functions for file input/output

using GZip
using DataStructures
using Iterators

##
# Parses a single line from the crosswiki dict file and returns a triple
#
function process_line(line::String)
    line = split(line, "\t")
    token = line[1]
    line = split(line[2])
    score = float64(line[2])
    entity = strip(line[1])
    return token, entity, score
end

##
# Constructs the sparse dictionary matrix
#
function read_dict(path::String)
    file = gzopen(path)

    V = Float64[]
    I = Uint32[]
    J = Uint32[]
    tokens = Dict{String, Uint32}()
    entities = Dict{String, Uint32}()
    sizehint(tokens, 4000)
    sizehint(entities, 4000000)

    count = 0
    for (token, entity, score) in imap(process_line, filter(line -> length(line) > 0, eachline(file)))
        count += 1
        if count % 10000 == 0
            println(count)
        end
        entity_index = get!(entities, entity, length(entities)+1)
        token_index = get!(tokens, token, length(tokens)+1)
        push!(I, entity_index)
        push!(J, token_index)
        push!(V, score)
    end
    close(file)

    return (tokens, entities, sparse(I, J, V))
end

read_dict() = read_dict("data/crosswiki-corrected-entities.gz")
