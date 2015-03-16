# NLP Project - Entity Linking
#
# EntityLinking
#   Contains the algorithms for linking entities

module EntityLinking

export link_naive
export link_tagme

include("Greedy.jl")
include("Naive.jl")
include("Tagme.jl")

end