# NLP Project - Entity Linking
#
# IO.Query
#   Query type and functionality

using LightXML

# A query defined by a series of tokens and their annotation
type Query
    tokens::Array{String}
    annotations::Array{Annotation}
    starttime::String

    function Query(xml::XMLElement)
        tokens = filter(x -> length(x) > 0, split(content(find_element(xml, "text")), r",|\.[^a-zA-Z]|\.$| "))
        annotations = read_annotations(xml)
        starttime = attribute(xml, "starttime")
        new(tokens, annotations, starttime)
    end
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
