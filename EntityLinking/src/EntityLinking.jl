# NLP Project - Entity Linking
#
# EntityLinking
#   Contains the algorithms for linking entities

module EntityLinking

export link_naive
export link_tagme
export link_template
export link_counts
export ngram_candidates

include("NgramCandidates.jl")
include("Greedy.jl")
include("Naive.jl")
include("Tagme.jl")
include("TemplateSelection.jl")
include("CountSimilarity.jl")

end
