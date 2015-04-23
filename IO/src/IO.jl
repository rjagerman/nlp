# NLP Project - Entity Linking
#
# IO
#   Contains various functions for file input/output

module IO

export read_queries, read_dict, read_counts
export Query, Session, Annotation

include("Queries.jl")
include("Crosswiki.jl")
include("Similarities.jl")

end
