# NLP Project - Entity Linking
#
# Main
#   Main entry point of the application
#   To execute run `julia main.jl`

# Push the current working directory to the LOAD_PATH so we can use module importing with the `using` keyword
if !("." in LOAD_PATH) push!(LOAD_PATH, ".") end

using IO
using Util
using Metrics

# Read tokens and entities
println("Loading crosswiki data")
crosswiki_file = "data/crosswikis-dict-preprocessed.gz"
tokens, entities, scores = cache("cache/crosswikis", () -> read_dict(crosswiki_file))

# Read queries and training data
println("Loading query data")
sessions = read_queries("data/query-data-train-set.xml")

# The ground truth queries
truth = Query[]
map(session -> append!(truth, session.queries), sessions)

# To do: make our own predictions on entities
predictions = truth

# Evaluate predictions and print them
strict_precision = Metrics.score(predictions, truth, Metrics.precision, true)
strict_recall    = Metrics.score(predictions, truth, Metrics.recall, true)
strict_f1        = Metrics.score(predictions, truth, Metrics.f1, true)
lazy_precision   = Metrics.score(predictions, truth, Metrics.precision, false)
lazy_recall      = Metrics.score(predictions, truth, Metrics.recall, false)
lazy_f1          = Metrics.score(predictions, truth, Metrics.f1, false)

println("Lazy precision: " * string(lazy_precision))
println("Lazy recall:    " * string(lazy_recall))
println("Lazy F1:        " * string(lazy_f1))
println("Strict precision: " * string(strict_precision))
println("Strict recall:    " * string(strict_recall))
println("Strict F1:        " * string(strict_f1))

# Done
println("Done")

