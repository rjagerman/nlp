using GZip
using JSON
using Util
using Requests
using PyCall

@pyimport requests as req

function create_dictionaries()

  # Read tokens and entities
  println("Loading crosswiki data")
  crosswiki_file = "data/crosswikis_filtered.gz"
  id_for_url = cache("cache/id_for_url", () -> create_id_for_url())

  count = 0
  data_for_entity = {entity => process_entity(entity,count += 1) for entity in filter_crosswiki(crosswiki_file)}


  return data_for_entity

end

function process_entity(entity::String,count::Int)
    println(entity,":",count)
    cats = {}
    links = {}

    query = {"format" => "json","action" => "query","prop" => "categories|links" ,"titles" => entity ,"cllimit" => "max","pllimit"=>"max" }

    response = req.get("http://en.wikipedia.org/w/api.php"; params=query)
    data = JSON.parse(convert(String,response["content"]))

    for val in values(data["query"]["pages"])
      if haskey(val,"links")
        links = vcat(links,map(x -> replace(x["title"]," ","_"),val["links"]))
      end
      if haskey(val,"categories")
        cats = vcat(cats,map(x -> replace(x["title"],"Category:",""),val["categories"]))
      end

    end


    while haskey(data,"query-continue")
      query = {"format" => "json","action" => "query","prop" => "categories|links" ,"titles" => entity,"cllimit" => "max","pllimit"=>"max" }
      if haskey(data["query-continue"],"categories")
        query["clcontinue"] = data["query-continue"]["categories"]["clcontinue"]
      end
      if haskey(data["query-continue"],"links")
         query["plcontinue"] = data["query-continue"]["links"]["plcontinue"]
      end
      response = req.get("http://en.wikipedia.org/w/api.php"; params=query)
      data = JSON.parse(convert(String,response["content"]))

      for val in values(data["query"]["pages"])
        if haskey(val,"links")
          links = vcat(links,map(x -> replace(x["title"]," ","_"),val["links"]))
        end
        if haskey(val,"categories")
          cats = vcat(cats,map(x -> replace(x["title"],"Category:",""),val["categories"]))
        end
      end
    end

    return (cats,links)
end




function create_id_for_url()
  # Read tokens and entities
  println("Loading crosswiki data")
  crosswiki_file = "data/update_crosswikis_without_stuff.gz"
  entities = cache("cache/filter_entities" , () -> filter_crosswiki(crosswiki_file))

  println(length(entities))
  id_for_url = Dict{String,Int64}()

  total_count = 0
  entity_count = 0

  for line in filter(line -> length(line) > 0, eachline(gzopen("data/enwiki.txt.gz")))
    obj = JSON.parse(line)
    url = replace(obj["url"],"http://en.wikipedia.org/wiki/","")
    if in(url,entities)
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

function filter_crosswiki(path::String)
  file = gzopen(path)
  entities = Set{String}()
  for (token, entity, score) in imap(process_line, filter(line -> length(line) > 0, eachline(file)))
    if score > 0.001
      push!(entities,entity)
    end
  end

  return entities
end

create_dict() = create_id_for_url()

cache_cats() = cache("cache/categories", () -> create_dictionaries())

cache_mapping() = cache("cache/id_for_url", () -> create_id_for_url())
