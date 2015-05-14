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
