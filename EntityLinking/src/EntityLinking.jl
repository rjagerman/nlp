# NLP Project - Entity Linking
#
# EntityLinking
#   Contains the algorithms for linking entities

module EntityLinking

export ngram_partitions
export link_naive

include("Naive.jl")
include("NgramPartitions.jl")

end