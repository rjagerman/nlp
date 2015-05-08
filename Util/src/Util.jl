# NLP Project - Entity Linking
#
# util
#   Contains various utility functions

module Util

using Metrics
using Gumbo
using Requests
using PyCall
@pyimport nltk.stem.porter as porter
stemmer = porter.PorterStemmer()

export cache
export string2bow
export crossval
export googlesearch
export clean

##
# Automatically caches the results of a function to a file and read that on future invocations
# Note that the result of the function must be serializable
#
function cache(path::String, func::Function)
    if isfile(path)
        return deserialize(open(path))
    else
        result = func();
        file = open(path, "w")
        serialize(file, result)
        close(file)
        return result
    end
end

# Stop words
stopwords = Set(["a", "a's", "able", "about", "above", "according", "accordingly", "across", "actually", "after",
    "afterwards", "again", "against", "ain't", "all", "allow", "allows", "almost", "alone", "along", "already", "also",
    "although", "always", "am", "among", "amongst", "an", "and", "another", "any", "anybody", "anyhow", "anyone",
    "anything", "anyway", "anyways", "anywhere", "apart", "appear", "appreciate", "appropriate", "are", "aren't",
    "around", "as", "aside", "ask", "asking", "associated", "at", "available", "away", "awfully", "be", "became",
    "because", "become", "becomes", "becoming", "been", "before", "beforehand", "behind", "being", "believe", "below",
    "beside", "besides", "best", "better", "between", "beyond", "both", "brief", "but", "by", "c'mon", "c's", "came",
    "can", "can't", "cannot", "cant", "cause", "causes", "certain", "certainly", "changes", "clearly", "co", "com",
    "come", "comes", "concerning", "consequently", "consider", "considering", "contain", "containing", "contains",
    "corresponding", "could", "couldn't", "course", "currently", "dear", "definitely", "described", "despite", "did",
    "didn't", "different", "do", "does", "doesn't", "doing", "don't", "done", "down", "downwards", "during", "each",
    "edu", "eg", "eight", "either", "else", "elsewhere", "enough", "entirely", "especially", "et", "etc", "even",
    "ever", "every", "everybody", "everyone", "everything", "everywhere", "ex", "exactly", "example", "except", "far",
    "few", "fifth", "first", "five", "followed", "following", "follows", "for", "former", "formerly", "forth", "four",
    "from", "further", "furthermore", "get", "gets", "getting", "given", "gives", "go", "goes", "going", "gone", "got",
    "gotten", "greetings", "had", "hadn't", "happens", "hardly", "has", "hasn't", "have", "haven't", "having", "he",
    "he'd", "he'll", "he's", "hello", "help", "hence", "her", "here", "here's", "hereafter", "hereby", "herein",
    "hereupon", "hers", "herself", "hi", "him", "himself", "his", "hither", "hopefully", "how", "how's", "howbeit",
    "however", "i", "i'd", "i'll", "i'm", "i've", "ie", "if", "ignored", "immediate", "in", "inasmuch", "inc", "indeed",
    "indicate", "indicated", "indicates", "inner", "insofar", "instead", "into", "inward", "is", "isn't", "it", "it'd",
    "it'll", "it's", "its", "itself", "just", "keep", "keeps", "kept", "know", "known", "knows", "last", "lately",
    "later", "latter", "latterly", "least", "less", "lest", "let", "let's", "like", "liked", "likely", "little", "look",
    "looking", "looks", "ltd", "mainly", "many", "may", "maybe", "me", "mean", "meanwhile", "merely", "might", "more",
    "moreover", "most", "mostly", "much", "must", "mustn't", "my", "myself", "name", "namely", "nd", "near", "nearly",
    "necessary", "need", "needs", "neither", "never", "nevertheless", "new", "next", "nine", "no", "nobody", "non",
    "none", "noone", "nor", "normally", "not", "nothing", "novel", "now", "nowhere", "obviously", "of", "off", "often",
    "oh", "ok", "okay", "old", "on", "once", "one", "ones", "only", "onto", "or", "other", "others", "otherwise",
    "ought", "our", "ours", "ourselves", "out", "outside", "over", "overall", "own", "particular", "particularly",
    "per", "perhaps", "placed", "please", "plus", "possible", "presumably", "probably", "provides", "que", "quite",
    "qv", "rather", "rd", "re", "really", "reasonably", "regarding", "regardless", "regards", "relatively",
    "respectively", "right", "said", "same", "saw", "say", "saying", "says", "second", "secondly", "see", "seeing",
    "seem", "seemed", "seeming", "seems", "seen", "self", "selves", "sensible", "sent", "serious", "seriously", "seven",
    "several", "shall", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "since", "six", "so",
    "some", "somebody", "somehow", "someone", "something", "sometime", "sometimes", "somewhat", "somewhere", "soon",
    "sorry", "specified", "specify", "specifying", "still", "sub", "such", "sup", "sure", "t's", "take", "taken",
    "tell", "tends", "th", "than", "thank", "thanks", "thanx", "that", "that's", "thats", "the", "their", "theirs",
    "them", "themselves", "then", "thence", "there", "there's", "thereafter", "thereby", "therefore", "therein",
    "theres", "thereupon", "these", "they", "they'd", "they'll", "they're", "they've", "think", "third", "this",
    "thorough", "thoroughly", "those", "though", "three", "through", "throughout", "thru", "thus", "tis", "to",
    "together", "too", "took", "toward", "towards", "tried", "tries", "truly", "try", "trying", "twas", "twice", "two",
    "un", "under", "unfortunately", "unless", "unlikely", "until", "unto", "up", "upon", "us", "use", "used", "useful",
    "uses", "using", "usually", "value", "various", "very", "via", "viz", "vs", "want", "wants", "was", "wasn't", "way",
    "we", "we'd", "we'll", "we're", "we've", "welcome", "well", "went", "were", "weren't", "what", "what's", "whatever",
    "when", "when's", "whence", "whenever", "where", "where's", "whereafter", "whereas", "whereby", "wherein",
    "whereupon", "wherever", "whether", "which", "while", "whither", "who", "who's", "whoever", "whole", "whom",
    "whose", "why", "why's", "will", "willing", "wish", "with", "within", "without", "won't", "wonder", "would",
    "wouldn't", "www", "yes", "yet", "you", "you'd", "you'll", "you're", "you've", "your", "yours", "yourself",
    "yourselves", "zero"])

# Converts a string to a bag-of-words representation
function string2bow(text::String)
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

# Performs cross validation
function crossval(training_set, training_truth, entity_linker, value_min, value_max, step)
    best_i = value_min
    best_score = 0.0
    for i = value_min:step:value_max
        predictions = entity_linker(training_set, i)
        score = Metrics.score(predictions, training_truth, Metrics.f1, true)
        if score > best_score
            best_score = score
            best_i = i
        end
    end
    return best_i
end

# Returns google search results over given set of queries
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

function clean(str)
    replace(replace(replace(lowercase(str), r"[^a-z0-9]+", " "), r"(\s+)", " "), r"\s$|^\s", "")
end

end
