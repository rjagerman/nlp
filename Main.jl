# NLP Project - Entity Linking
#
# Main
#   Main entry point of the application
#   To execute run `julia main.jl <algorithm> <path/to/query/file>`
#   where <algorithm> is either "naive", "tagme" or "probabilistc"

# Push the current working directory to the LOAD_PATH so we can use module importing with the `using` keyword
if !("." in LOAD_PATH) push!(LOAD_PATH, ".") end

using IO
using Util
using Metrics
using Match
using EntityLinking

# Check command line arguments
@match length(ARGS) begin
    2 => nothing
    x => (println("Usage: julia Main.jl <algorithm> <query-file>"); exit(1))
end
query_file = ARGS[2]
if !isfile(query_file)
    println("Data file " * query_file * " not found")
    exit(1)
end

# Read queries and training data
println("Loading query data")
truth_sessions = read_queries(query_file)
prediction_sessions = read_queries(query_file)

# Flatten sessions to arrays, ignoring the session structure
truth_queries = Query[]
prediction_queries = Query[]
map(session -> append!(truth_queries, session.queries), truth_sessions)
map(session -> append!(prediction_queries, session.queries), prediction_sessions)
for query in prediction_queries query.annotations = [] end # Remove existing annotations from our predictions array

# Create model for the specified algorithm
println("Loading model $(ARGS[1])")
model = @match ARGS[1] begin
    "naive" => NaiveModel("crosswiki.gz")
    "tagme" => TagmeModel("tagme-NLP-ETH-2015")
    "lda" => LDAModel("crosswiki.gz", "data/lda/predictions", query_file[1:end-3] * "query")
    x => (println("Unknown model type"); exit(1))
end

# Compute annotations
println("Annotating $(length(prediction_queries)) queries")
annotate!(prediction_queries, model)

# Evaluate predictions and print the scores
strict_precision = Metrics.score(prediction_queries, truth_queries, Metrics.precision, true)
strict_recall    = Metrics.score(prediction_queries, truth_queries, Metrics.recall, true)
strict_f1        = Metrics.score(prediction_queries, truth_queries, Metrics.f1, true)
lazy_precision   = Metrics.score(prediction_queries, truth_queries, Metrics.precision, false)
lazy_recall      = Metrics.score(prediction_queries, truth_queries, Metrics.recall, false)
lazy_f1          = Metrics.score(prediction_queries, truth_queries, Metrics.f1, false)

println("Strict precision:  " * string(strict_precision))
println("Strict recall:     " * string(strict_recall))
println("Strict F1:         " * string(strict_f1))
println("Relaxed precision: " * string(lazy_precision))
println("Relaxed recall:    " * string(lazy_recall))
println("Relaxed F1:        " * string(lazy_f1))

# Done
println("Done")
