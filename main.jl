# NLP Project - Entity Linking
#
# Main
#   Main entry point of the application
#   To execute run `julia main.jl`

include("metrics.jl")
include("util.jl")
include("io.jl")

# Read tokens and entities
println("Loading crosswiki data")
crosswiki_file = "data/crosswikis-dict-preprocessed.gz"
tokens, entities, scores = util.cache("cache/crosswikis", () -> io.crosswiki.read(crosswiki_file))

# Read queries and training data
println("Loading query data")
sessions = io.query.read("data/query-data-train-set.xml")

for session in sessions
    for query in session.queries
        for token in query.tokens
            print(token * " ")
        end
        println()
        for annotation in query.annotations
            print("    " * annotation.entity * string(annotation.range))
        end
        println()
    end
end

# Done
println("Done")


