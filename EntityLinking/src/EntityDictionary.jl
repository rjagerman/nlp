using GZip

# An entity with a prior score
type Entity
    uri::String
    prior::Float64
    Entity(uri::String) = new(uri, 0.0)
    Entity(uri::String, prior::Float64) = new(uri, prior)
end

# An entity dictionary, mapping tokens to an array of entities
typealias EntityDictionary Dict{String, Array{Entity}}

# Create entity dictionary from gzipped crosswikis file
function read_crosswikis(crosswiki::String)
    dictionary = EntityDictionary()
    for line in filter(line -> !isempty(line), eachline(gzopen(crosswiki)))
        token, (uri, score) = (split(line, "\t")[1], split(split(line, "\t")[2]))
        push!(get!(dictionary, token, Entity[]), Entity(uri, float64(score)))
    end
    dictionary
end
