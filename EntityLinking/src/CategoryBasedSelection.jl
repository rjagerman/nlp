# NLP Project - Entity Linking


using IO
using Util
using Iterators
import Base.Collections: enqueue!, dequeue!, PriorityQueue
import Base.Order: Reverse

##
# Entity Linking example
#
# Typical usage with a candidates function:
#   ...
#   my_annotated_queries = link_template(sessions, some_candidate_function)
#   ...
#
function link_category(sessions, candidates::Function)

     # Read tokens and entities
    println("Loading crosswiki data")
    crosswiki_file = "data/update_crosswikis_without_stuff.gz"
    tokens, entities, scores = cache("cache/crosswikis", () -> read_dict(crosswiki_file))

     # Generate the inverse index
    inv_tokens = {index => token for (token, index) in tokens}
    inv_entities = {index => entity for (entity, index) in entities}

    max_scores = cache("cache/max_score_dict", () -> max_score_dict(scores, tokens, inv_entities))

    cached_entities = cache("cache/categories", () -> create_dictionaries())

    println("Start Scoring")
    # Ignore session structure
    queries = Query[]
    map(session -> append!(queries, session.queries), sessions)
    count = 0
    # Link using a greedy approach with naive candidates
    total = size(queries)[1]

    for query in queries
        annotate_query(query,link_single_query(query,cached_entities,candidates,max_scores))
        count += 1
        println(count,"/",size(queries)[1])
    end

    # Return all the queries (for scoring)
    return queries

end

##
# Links a single query
#
function link_single_query(query,data,candidates::Function,max_scores)

    # Clear previous annotations (e.g. from loading from file)
    query.annotations = []


    #score lookup: entity1,entity2 -> score
    scored_candidates = PriorityQueue(Reverse)



    # Process all the candidates
    map!(clean,query.tokens)
    cands = candidates(query,max_scores)
    println(query,"  size:", length(cands))
    combis = {c => cands for c in cands}
    for combi in combis
      s = score_entity(combi,data)
      enqueue!(scored_candidates,combi[1],s)
      print(combi[1],":",s," ")
    end
    println()
    return scored_candidates

end

function score_entity(combi,data)
  entitiy_score = 0
  entitiy = combi[1]
  entitiy_set = combi[2]
  l = 1.0*length(entitiy_set)[1]

  for e in entitiy_set
    entitiy_score += score({entitiy,e},data)
  end
  println(l)
  return entitiy_score
end

function score(pair, data)
  ann1 = pair[1]
  ann2 = pair[2]

  entity1 = ann1.entity
  entity2 = ann1.entity

  p1 = ann1.prior
  p2 = ann2.prior

  if haskey(data,entity1) && haskey(data,entity2)
    cat1 = data[entity1][1]
    cat2 = data[entity2][1]
    links1 = data[entity1][2]
    links2 = data[entity2][2]

    #have to do this check since i messed up the category array creation...
    if cat1 != Array{String} && cat2 != Array{String}
        intersection = 1.0*size(intersect(cat1,cat2))[1]
        union_size = 1.0*size(union(cat1,cat2))[1]
        size1 = 1.0*size(cat1)[1]
        size2 = 1.0*size(cat2)[1]
        return (intersection/size1)*link_indicator(links1,entity2,2)*p1 + p2*link_indicator(links2,entity1,2)*(intersection/size2)

    else
      return p1*p2
    end

  else
    return p1*p2
  end
end

function link_indicator(link1,entity2,n)
  if in(entity2,link1)
    return n
  else
    return 1
  end
end
