# NLP Project - Entity Linking
#
# IO
#   Contains various functions for file input/output

module IO

export read_queries, read_dict
export Query, Session, Annotation

include("Queries.jl")
include("Crosswiki.jl")

end
