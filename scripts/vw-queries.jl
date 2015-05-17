##
# Converts XML query datasets to a bag-of-words format for Vowpal Wabbit
# Usage:
#   julia scripts/vw-queries.jl <path/to/query-data-...-set.xml>
#

if !("." in LOAD_PATH) push!(LOAD_PATH, ".") end

using IO
using GZip
using JSON
using Util

if length(ARGS) != 1
    println("Usage:")
    println("julia scripts/vw-queries.jl <path/to/query-data-...-set.xml>")
    println("Pipeline output into the following command to compute predictions:")
    println("  vw -i <path/to/model> -p <path/to/predictions> -t")
    exit(1)
end

query_file = ARGS[1]
sessions = read_queries(query_file)
queries = Query[]
map(session -> append!(queries, session.queries), sessions)

search_results = cache("cache/googleresults-$(query_file[6:end]).dat", () -> googlesearch(queries))

count = 0
for query in queries
    text = join(query.tokens, " ")
    count += 1
    output_features = string2bow(text * " " * join(search_results["processed"][count], " "))
    print("'" * string(count) * "| ")
    for feature in keys(output_features)
        print(feature * ":" * string(output_features[feature]) * " ")
    end
    if length(output_features) == 0
        print("1:1.0")
    end
    println()
end
