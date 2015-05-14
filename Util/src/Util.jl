# NLP Project - Entity Linking
#
# util
#   Contains various utility functions

module Util

using Metrics

include("Ngram.jl")
include("Cache.jl")
include("TextPreprocessing.jl")
include("Google.jl")
include("Range.jl")

export cache
export ngrams
export string2bow
export googlesearch
export clean
export overlaps

end
