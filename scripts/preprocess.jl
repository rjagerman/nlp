using Util
using PyCall
@pyimport nltk.stem.porter as porter
stemmer = porter.PorterStemmer()

##
# Converts a string to a bag-of-words representation
#
function string_to_bow(text::String)
    text = lowercase(replace(text, r"[^a-zA-Z]+", " "))
    features = split(text, r"\s+")
    features = filter(x -> length(x) >= 3, features)
    features = filter(x -> length(x) <= 30, features)
    features = filter(x -> !in(x, stopwords), features)
    features = map(x -> pycall(stemmer["stem"], PyAny, x), features)
    output_features = Dict{String, Float64}()
    for feature in features
        output_features[feature] = get(output_features, feature, 0.0) + 1.0
    end
    return output_features
end
