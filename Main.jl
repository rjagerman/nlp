# NLP Project - Entity Linking
#
# Main
#   Main entry point of the application
#   To execute run `julia main.jl <algorithm>`
#   where <algorithm> is either "naive" or "tagme"

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

# Check data file existence
query_file = ARGS[2]
if !isfile(query_file)
    println("Data file " * query_file * " not found")
    exit(1)
end

# Read queries and training data
println("Loading query data")
sessions_truth = read_queries(query_file)
sessions_predictions = read_queries(query_file)

# The ground truth queries
truth = Query[]
map(session -> append!(truth, session.queries), sessions_truth)

# Compute predictions, according to the specified algorithm
predictions = @match ARGS[1] begin
    "naive" => link_naive(sessions_predictions)
    "tagme" => link_tagme(sessions_predictions)
    x => (println("Unknown algorithm"); exit(1))
end

# Print predictions
# for (prediction, t) in zip(predictions, truth)
#     println(join(prediction.tokens, " "))
#     println("  Predictions:")
#     for annotation in prediction.annotations
#         println("    " * string(annotation))
#     end
#     println("  Truth:")
#     for annotation in t.annotations
#         println("    " * string(annotation))
#     end
# end

# Evaluate predictions and print the scores
strict_precision = Metrics.score(predictions, truth, Metrics.precision, true)
strict_recall    = Metrics.score(predictions, truth, Metrics.recall, true)
strict_f1        = Metrics.score(predictions, truth, Metrics.f1, true)
lazy_precision   = Metrics.score(predictions, truth, Metrics.precision, false)
lazy_recall      = Metrics.score(predictions, truth, Metrics.recall, false)
lazy_f1          = Metrics.score(predictions, truth, Metrics.f1, false)

println("Strict precision:  " * string(strict_precision))
println("Strict recall:     " * string(strict_recall))
println("Strict F1:         " * string(strict_f1))
println("Relaxed precision: " * string(lazy_precision))
println("Relaxed recall:    " * string(lazy_recall))
println("Relaxed F1:        " * string(lazy_f1))

# Done
println("Done")
