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
function process_count_line(line::String)
    line = split(line, "\t")
    firstEntity = line[1]
    secondEntity = line[2]
    score = line[3]
    return firstEntity, secondEntity, score
end

##
# Constructs the sparse dictionary matrix
#
function read_counts(path::String, path2::String)
    file = gzopen(path)

    counts = Dict{(String, String), Uint32}()

    sizehint(counts, 50000000)

    for (firstEntity, secondEntity, score) in imap(process_count_line, filter(line -> length(line) > 0, eachline(file)))
        counts[(firstEntity, secondEntity)] = score
    end
    close(file)

    file = gzopen(path)

    for (firstEntity, secondEntity, score) in imap(process_count_line, filter(line -> length(line) > 0, eachline(file)))
        counts[(firstEntity, secondEntity)] = score
    end
    close(file)

    return (counts)
end

read_counts() = read_counts("data/entity-cooccurrence-counts-part-1", "data/entity-cooccurrence-counts-part-2")
