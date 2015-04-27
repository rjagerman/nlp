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
    score = int(line[3])
    return firstEntity, secondEntity, score
end

##
# Constructs the sparse dictionary matrix
#
function read_counts(path::String, path2::String)
    file = gzopen(path)

    counts = Dict{(String, String), Uint32}()

    sizehint(counts, 5000000)

    count = 0
    for (firstEntity, secondEntity, score) in imap(process_count_line, filter(line -> length(line) > 0, eachline(file)))
        count += 1
        if count % 1000000 == 0
            println(count)
        end
        if (count > 5000000)
          break
        end
        if (score > 0)
          counts[(firstEntity, secondEntity)] = score
        end
    end
    close(file)
    ### processing of second file
    #file = gzopen(path2)
    #for (firstEntity, secondEntity, score) in imap(process_count_line, filter(line -> length(line) > 0, eachline(file)))
    #    count += 1
    #    if count % 100000 == 0
    #        println(count)
    #    end
    #    if (score > 20)
    #      counts[(firstEntity, secondEntity)] = score
    #    end
    #end
    #close(file)
    ###


    return (counts)
end

read_counts() = read_counts("data/entity-cooccurrence-counts-part-1.gz", "data/entity-cooccurrence-counts-part-2.gz")
