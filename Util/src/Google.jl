using Gumbo
using Requests

##
# Returns google search results over given set of queries as both the full google HTML page and extracted search
# snippets
#
function googlesearch(queries)
    plaintext_results = String[]
    extracted_results = Array{String}[]
    count = 0
    for query in queries
        count += 1
        url = "https://www.google.ch/search"
        initial_timeout = int(1+rand()*3)
        println("""Searching for $(join(query.tokens, " ")) in $(initial_timeout) seconds [$(count)/$(length(queries))]""")
        sleep(initial_timeout)
        resp = get(url; query = {"q" => join(query.tokens, " "), "hl" => "en-us"})
        while resp.status != 200
            println("Could not get `$(url)` (Status: $(resp.status))")
            failure_timeout = int(30+rand()*30)
            println("Timeout: $(failure_timeout) seconds")
            sleep(failure_timeout)
            resp = get(url)
        end
        if resp.status == 200
            doc = parsehtml(resp.data)
            extracted = String[]
            for elem in breadthfirst(doc.root)
                if typeof(elem) != HTMLText
                    if "class" in keys(elem.attributes) && (elem.attributes["class"] == "st" || elem.attributes["class"] == "r")
                        output = ""
                        for e in preorder(elem)
                            if typeof(e) == HTMLText
                                output *= e.text
                            end
                        end
                        push!(extracted, output)
                    end
                end
            end
            push!(plaintext_results, resp.data)
            push!(extracted_results, extracted)
        end
    end
    return ["html" => plaintext_results, "processed" => extracted_results]

end

##
# Gets the full plaintext contents of given HTML node
#
function plaintext(elem::HTMLNode)
    if typeof(elem) == HTMLText
        println(elem)
        return elem.text
    end
    if typeof(elem) == HTMLNode
        out = ""
        for child in elem.children
            out *= plaintext(child)
        end
        return out
    end
    return ""
end
