# NLP Project - Entity Linking
#
# EntityLinking
#   Contains the algorithms for linking entities

module EntityLinking

# An entity linking model
abstract EntityLinkingModel

include("Annotator.jl")
include("EntityDictionary.jl")
include("Naive.jl")
include("Tagme.jl")
include("LDA.jl")

# Types
export NaiveModel
export TagmeModel
export LDAModel

# Functions
export annotate!

end
