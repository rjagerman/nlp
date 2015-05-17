# NLP Project - Entity Linking
#
# IO.Read
#   Contains functions for reading query data

using LightXML
using DataStructures
using Iterators

##
# Reads annotated queries
#
function read_queries(path::String)
    doc = parse_file(path)
    [Session(session) for session in collect(filter(x -> name(x) == "session", child_elements(root(doc))))]
end
