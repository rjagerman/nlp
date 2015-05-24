# NLP Project - Entity Linking
#
# Metrics
#   Contains various functions to compute metrics such as precision, recall and F_1

module Metrics

using IO
using Match

##
# Computes the precision
#
function precision(prediction::Set, truth::Set)
    return @match length(prediction) begin
        0 => 1.0
        x => length(intersect(prediction, truth)) / x
    end
end

##
# Computes the recall
#
function recall(prediction::Set, truth::Set)
    return @match length(truth) begin
        0 => 0 # length(prediction) == 0 ? 1.0 : 0.0
        x => length(intersect(prediction, truth)) / x
    end
end

##
# Computes the F1 score
#
function f1(prediction::Set, truth::Set)
    p = precision(prediction, truth)
    r = recall(prediction, truth)
    @match p+r begin
        0 => 0.0
        x => 2.0 * (p * r) / x
    end
end

##
# Computes a score in a strict or lazy way using given metric function
#
function score(prediction::Query, truth::Query, metric::Function, strict::Bool)
    if strict
        return metric(Set(prediction.annotations), Set(truth.annotations))
    else
        return metric(Set([x.entity for x in prediction.annotations]), Set([x.entity for x in truth.annotations]))
    end
end

##
# Computes a mean score over arrays of predictions and truths and filters out queries that have 0 annotations
#
function score(predictions::Array{Query}, truth::Array{Query}, metric::Function, strict::Bool)
    filtered = collect(filter(x -> length(x[2].annotations) > 0, zip(predictions, truth)))
    @match length(filtered) begin
        0 => 0.0
        x => mean([score(q1, q2, metric, strict) for (q1, q2) in filtered])
    end
end

end
