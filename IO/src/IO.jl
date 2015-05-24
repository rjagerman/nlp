# NLP Project - Entity Linking
#
# IO
#   Contains various functions for file input/output of query data

module IO

export read_queries, write_queries
export Query, Session, Annotation

include("Annotation.jl")
include("Query.jl")
include("Session.jl")
include("Read.jl")
include("Write.jl")

end
