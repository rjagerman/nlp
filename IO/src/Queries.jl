# NLP Project - Entity Linking
#
# IO.Queries
#   Contains functions for reading query data

using LightXML
using DataStructures
using Iterators

# An annotation defined by an entity and a range
type Annotation
    entity::String
    range::(Int, Int)
end
isequal(a1::Annotation, a2::Annotation) = (a1.entity == a2.entity && a1.range == a2.range)
==(a1::Annotation, a2::Annotation) = isequal(a1, a2)
Base.hash(a::Annotation) = (hash(a.entity) & hash(a.range))

# A query defined by a series of tokens and their annotation
type Query
    tokens::Array{String}
    annotations::Array{Annotation}
end

# A session defined by a series of queries
type Session
    queries::Array{Query}
end

##
# Reads annotations from a query xml element
#
function read_annotations(query::XMLElement)
    annotations = Annotation[]
    annotation_index = 1
    for annotation in filter(x -> name(x) == "annotation", child_elements(query))
        nr_of_tokens = length(split(content(find_element(annotation, "span"))))
        if find_element(annotation, "target") != nothing
            annotation = Annotation(
                content(find_element(annotation, "target"))[30:end],
                (annotation_index, annotation_index + nr_of_tokens - 1)
            )
            push!(annotations, annotation)
        end
        annotation_index += nr_of_tokens
    end
    return annotations
end

##
# Reads queries from a session xml element
# 
function read_queries(session::XMLElement)
    queries = Query[]
    for query in filter(x -> name(x) == "query", child_elements(session))
        tokens = split(content(find_element(query, "text")))
        annotations = read_annotations(query)
        push!(queries, Query(tokens, annotations))
    end
    return queries
end

##
# Reads annotated queries
#
function read_queries(path::String)
    doc = parse_file(path)
    sessions = Session[]
    for session in filter(x -> name(x) == "session", child_elements(root(doc)))
        queries = read_queries(session)
        push!(sessions, Session(queries))
    end
    return sessions
end

