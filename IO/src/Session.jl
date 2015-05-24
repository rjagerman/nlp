# NLP Project - Entity Linking
#
# IO.Session
#   Session type and functionality

using LightXML

# A session defined by a series of queries
type Session
    id::String
    numqueries::Int
    queries::Array{Query}

    function Session(xml::XMLElement)
        id = attribute(xml, "id")
        numqueries = int(attribute(xml, "numqueries"))
        queries = [Query(query) for query in collect(filter(x -> name(x) == "query", child_elements(xml)))]
        new(id, numqueries, queries)
    end
end
