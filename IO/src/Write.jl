# NLP Project - Entity Linking
#
# IO.Write
#   Contains functions for writing query data

using LightXML
using DataStructures
using Iterators

##
# Writes annotated queries
#
function write_queries(sessions::Array{Session}, path::String)

    doc = XMLDocument()
    root = create_root(doc, "webscope")
    set_attribute(root, "numqueries", sum([length(session.queries) for session in sessions]))
    set_attribute(root, "numsessions", length(sessions))

    for session in sessions
        xml_session = new_child(root, "session")
        set_attributes(xml_session, {"id" => session.id, "numqueries" => session.numqueries})

        for query in session.queries
            xml_query = new_child(xml_session, "query")
            set_attribute(xml_query, "starttime", query.starttime)
            text = new_child(xml_query, "text")
            add_cdata(doc, text, join(query.tokens, " "))

            previous = 0

            for (range, annotation) in sort([(annotation.range, annotation) for annotation in query.annotations])
                if range[1] != previous + 1
                    for index = previous + 1:range[1] - 1
                        add_xml_annotation(doc, xml_query, query.tokens, (index, index), "")
                    end
                end
                add_xml_annotation(doc, xml_query, query.tokens, range, annotation.entity)
                previous = range[2]
            end
            if previous < length(query.tokens)
                for index = previous + 1:length(query.tokens)
                    add_xml_annotation(doc, xml_query, query.tokens, (index, index), "")
                end
            end

        end
    end

    # Save to file
    save_file(doc, path)
end


##
# Add UTF8 support to LightXML cdata elements
#
function LightXML.new_cdatanode(xdoc::XMLDocument, txt::UTF8String)
        p = ccall(LightXML.xmlNewCDataBlock, LightXML.Xptr, (LightXML.Xptr, LightXML.Xstr, LightXML.Cint), xdoc.ptr, txt, sizeof(txt)+1)
        LightXML.XMLNode(p)
end
LightXML.add_cdata(xdoc::XMLDocument, x::XMLElement, txt::UTF8String) = add_child(x, LightXML.new_cdatanode(xdoc,txt))


##
# Adds an xml annotation for given entity or an empty annotation if no entity is provided
#
function add_xml_annotation(doc, query, tokens, range, entity)
    xml_annotation = new_child(query, "annotation")
    span = new_child(xml_annotation, "span")
    add_cdata(doc, span, replace(join(tokens[range[1]:range[2]], " "), r"[\+\"\'\`\,\.\<\>\?\\/()\[\]\{\}]+ | [\"\'\`\,\.\<\>\?\\/()\[\]\{\}\+]+|[\+\"\'\`\,\.\<\>\?\\/()\[\]\{\}]+$|^[\"\'\`\,\.\<\>\?\\/()\[\]\{\}\+]+", ""))
    if entity != ""
        target = new_child(xml_annotation, "target")
        add_cdata(doc, target, "http://en.wikipedia.org/wiki/" * entity)
    end
end
