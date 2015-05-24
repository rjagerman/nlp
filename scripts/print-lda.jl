##
# Show top entries for LDA topics in given file
#
# Usage:
#   julia scripts/print-lda.jl <lda-file> <nr-of-results-per-topic> [query-file]

if !("." in LOAD_PATH) push!(LOAD_PATH, ".") end
using IO
using Match

import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse

@match length(ARGS) begin
    2 => nothing
    3 => nothing
    x => (println("Usage: julia scripts/print-lda.jl <lda-file> <nr-of-results-per-topic> [query-file]"); exit(1))
end

file = ARGS[1]
number_of_entries_per_topic = int(ARGS[2])

queries = Query[]
if length(ARGS) == 3
    sessions = read_queries(ARGS[3])
    map(session -> append!(queries, session.queries), sessions)
end

type Entity
    name::String
    score::Float64
end

typealias EntityQueue PriorityQueue{Entity, Float64}

result = Dict{Int, EntityQueue}()
count = 0
for line in eachline(open(file))
    count += 1
    if count % 10000 == 0
        println(count)
    end
    features = split(line)
    entity = features[end]
    topics = map(float64, features[1:end-1])
    topics /= sum(topics)
    for i = 1:length(topics)
        pq = get!(result, i, EntityQueue())
        enqueue!(pq, Entity(entity, topics[i]), topics[i])
        if length(pq) > number_of_entries_per_topic
            dequeue!(pq)
        end
    end
end

for k = 1:length(result)
    v = result[k]
    println("Topic $(k)")
    entities = Entity[]
    while !isempty(v)
        push!(entities, dequeue!(v))
    end
    reverse!(entities)
    for e in entities
        if length(ARGS) == 3
            println("""$(join(queries[int(e.name)].tokens, " "))$(" " ^ max(0, 40 - length(e.name)))$(e.score)""")
        else
            println("""$(e.name)$(" " ^ max(0, 40 - length(e.name)))$(e.score)""")
        end
    end
    println()
end
