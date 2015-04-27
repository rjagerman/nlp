using GZip
using JSON
using Util

function create_dictionaries(path::String)

  # Read tokens and entities
  println("Loading crosswiki data")
  crosswiki_file = "data/crosswikis_without_wikipedia_wiki.gz"
  tokens, entities, scores = cache("cache/crosswikis", () -> read_dict(crosswiki_file))

  url_prefix_len = length("http://en.wikipedia.org/wiki/") + 1



  #url -> (id,array of annotation ids)
  entry_for_url = Dict{String,Set{String}}()

  count_total = 0;
  count_wiki = 0;

  for line in eachline(gzopen(path))
    obj = JSON.parse(line)
    annotations = Set{String}()

    url = obj["url"][url_prefix_len:end]

    if haskey(entities, url)
      for link in obj["annotations"]
        push!(annotations,link["uri"])
      end
      entry_for_url[url] = annotations
      count_wiki += 1
      if count_wiki % 10000 == 0
          println(string("Entities used: ", count_wiki) )
      end


    end

    count_total += 1
    if count_total % 10000 == 0
        println(string("Total processed: ", count_total))
    end


  end
  return entry_for_url, url_for_id


end

create_dictionaries() = create_dictionaries("data/enwiki.txt.gz")
