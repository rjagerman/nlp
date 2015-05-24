##
# Converts wikipedia JSON articles to a bag-of-words format for Vowpal Wabbit
# Usage:
#   julia scripts/vw-wikipedia.jl <path/to/enwiki.txt.gz>
#
# Pipeline output into the following command to train model:
#   vw --lda <num-topics> -b <num-hash-bits> --lda_D <num-documents> --passes <num-passes> -f <path/to/store/model> --cache_file <path/to/tmp/cache> --minibatch 256 --lda_alpha 0.1 --lda_rho 0.1  --power_t 0.5 --initial_t 1
#
# Pipeline output into the following command to compute predictions:
#   vw -i <path/to/model> -p <path/to/predictions> -t
#

if !("." in LOAD_PATH) push!(LOAD_PATH, ".") end

using GZip
using JSON
using Util
include("preprocess.jl")

if length(ARGS) != 1
    println("Usage:")
    println("julia scripts/vw-wikipedia.jl <path/to/enwiki.txt.gz>")
    println("Pipeline output into the following command to train model:")
    println("  vw --lda <num-topics> -b <num-hash-bits> --lda_D <num-documents> --passes <num-passes> -f <path/to/store/model> --cache_file <path/to/tmp/cache> --minibatch 256 --lda_alpha 0.1 --lda_rho 0.1  --power_t 0.5 --initial_t 1")
    println("Pipeline output into the following command to compute predictions:")
    println("  vw -i <path/to/model> -p <path/to/predictions> -t")
    exit(1)
end

for line in eachline(gzopen(ARGS[1]))
    obj = JSON.parse(line)
    entity = obj["url"][1 + length("http://en.wikipedia.org/wiki/"):end]
    features = string_to_bow(obj["text"])
    print("'$(entity)| ")
    for feature in keys(features)
        print(feature * ":" * string(features[feature]) * " ")
    end
    println()
end
