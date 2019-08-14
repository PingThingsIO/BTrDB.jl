using Base64

struct RawPoint
    time::Int64
    value::Float64
end

struct Stream
    uuid::String
    name::String
    collection::String
    tags::Dict{String,String}
    annotations::Dict{String,Any}
end

###############################################################################
# Constructors
###############################################################################

function Stream(data::Dict{String,Any})
    tags = decodeTags(data["tags"])
    Stream(
        decodeUUID(data["uuid"]),
        tags["name"],
        data["collection"],
        tags,
        decodeAnnotations(data["annotations"]),
    )
end



###############################################################################
# Module Only Utility Functions
###############################################################################

function decodeTags(data)
    tags = Dict{String, String}()
    for item in data
        tags[item["key"]] = item["val"]["value"]
    end
    return tags
end

function decodeAnnotations(data)
    tags = Dict{String, Any}()
    for item in data
        tags[item["key"]] = JSON.parse(item["val"]["value"])
    end
    return tags
end

