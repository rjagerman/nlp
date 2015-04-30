using GZip
using JSON
using Util
using Requests

function create_dictionaries()

  # Read tokens and entities
  println("Loading crosswiki data")
  crosswiki_file = "data/crosswikis_filtered.gz"
  tokens, entities, scores = cache("cache/crosswikis", () -> read_dict(crosswiki_file))

  data_for_entity = Dict{String,(Array{String},Array{String})}()

  tmp = map(entity -> process_entity(string(entity)),keys(entities))

  for line in tmp
    data_for_entry[line[1]] = (line[2],line[3])
  end

  return data_for_entity

end

function process_entity(entity::String)
    println(entity)
    cats = Array{String}
    links = Array{String}

    response = get("http://en.wikipedia.org/w/api.php"; query = {"format" => "json","action" => "query","prop" => "categories|links" ,"titles" => entity ,"cllimit" => "max","pllimit"=>"max" })
    data = JSON.parse(response.data)

    for val in values(data["query"]["pages"])
      if haskey(val,"links")
        links = vcat(links,map(x -> replace(x["title"]," ","_"),val["links"]))
      end
      if haskey(val,"categories")
        cats = vcat(cats,map(x -> replace(x["title"],"Category:",""),val["categories"]))
      end

    end


    while haskey(data,"query-continue")
      query = {"format" => "json","action" => "query","prop" => "categories|links" ,"titles" => entity ,"cllimit" => "max","pllimit"=>"max" }
      if haskey(data["query-continue"],"categories")
        query["clcontinue"] = data["query-continue"]["categories"]["clcontinue"]
      end
      if haskey(data["query-continue"],"links")
         query["plcontinue"] = data["query-continue"]["links"]["plcontinue"]
      end
      response = get("http://en.wikipedia.org/w/api.php"; query=query)
      data = JSON.parse(response.data)

      for val in values(data["query"]["pages"])
        if haskey(val,"links")
          links = vcat(links,map(x -> replace(x["title"]," ","_"),val["links"]))
        end
        if haskey(val,"categories")
          cats = vcat(cats,map(x -> replace(x["title"],"Category:",""),val["categories"]))
        end
      end
    end
    println(cats,links)

    return entity,cats,links
end




function create_id_for_url()
  # Read tokens and entities
  println("Loading crosswiki data")
  crosswiki_file = "data/crosswikis_filtered.gz"
  tokens, entities, scores = cache("cache/crosswikis", () -> read_dict(crosswiki_file))

  id_for_url = Dict{String,Int64}()

  total_count = 0
  entity_count =0

  for line in filter(line -> length(line) > 0, eachline(gzopen("data/enwiki.txt.gz")))
    obj = JSON.parse(line)
    url = replace(obj["url"],"http://en.wikipedia.org/wiki/","")
    if haskey(entities,url)
      id = obj["id"][1]
      id_for_url[url] = id

      entity_count += 1
      if entity_count % 1000 == 0
        println("Entity COunt: ", string(entity_count))
        println("Entities Left: ", string(length(entities)))
      end
      delete!(entities,url)
    end

    if isempty(entities)
      break
    end

    total_count += 1
    if total_count % 1000 == 0
      println("TotalCount: ", string(total_count))
    end
  end

  return id_for_url
end



create_dict() = create_id_for_url()

cache_cats() = cache("cache/categories", () -> create_dictionaries())

cache_mapping() = cache("cache/id_for_url", () -> create_id_for_url())
