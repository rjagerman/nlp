# NLP Project - Entity Linking
#
# NgramPartition
#   Contains the functionality to recursively generate all possible ngram partitions

ngram_partitions(tokens, max_length) = Task(() -> produce_ngram_partitions(tokens, max_length))

function produce_ngram_partitions(tokens, max_length)
    max_index = min(length(tokens), max_length)
    for end_index = 1:max_index
        if end_index == length(tokens)
            produce([join(tokens[1:end_index], " ")])
        else
            for latter_partitions in Task(() -> produce_ngram_partitions(tokens[end_index+1:length(tokens)], max_length))
                arr = [join(tokens[1:end_index], " "); latter_partitions]
                produce(arr)
            end
        end
    end
end
