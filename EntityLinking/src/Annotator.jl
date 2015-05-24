using IO

##
# Annotates all queries in given array using given model
# The model type must implement a function
#   annotate(query::Query, model::EntityLinkingModel)
# which returns an annotated query
#
function annotate!(queries::Array{Query}, model::EntityLinkingModel)
    for query in queries
        annotate!(query, model)
    end
end
