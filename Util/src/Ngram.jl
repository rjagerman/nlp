##
# Ngram iterator
#
ngrams(tokens::Array{String}; max_size=100) = Task(() -> iterate_ngrams_producer(tokens, max_size))

function iterate_ngrams_producer(tokens::Array{String}, max_size)
    for size = min(max_size, length(tokens)):-1:1
        for index = 1:1+(length(tokens)-size)
            produce((index, index+size - 1), join(tokens[index:index + size - 1], " "))
        end
    end
end
