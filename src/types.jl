using Base64

struct RawPoint
    time::Int64
    value::Float64
end

mutable struct Stream
    uuid::String
    name::String
    collection::String
    tags::Dict{String,String}
    annotations::Dict{String,Any}
    version::Int64
    propertyVersion::Int64
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
        0,
        0
    )
end

function RawPoint(data::Dict{String,Any})
    return RawPoint(parse(Int64, data["time"]), data["value"])
end


###############################################################################
# Object functions
###############################################################################

# function get(Stream, String)

# end

###############################################################################
# Module Only Utility Functions
###############################################################################

# Example chained usage:
#   BTrDB.decodeTags(JSON.parse(encodeTags(ss.tags)))

# function tags2array(tags::Dict{String, String})
#     fields = ["distiller", "ingress", "name", "unit"]
#     data = []
#     for f in fields
#         if haskey(tags, f)
#             push!(data, Dict{String, Any}("key" => f, "val" => Dict{String, String}("value" => tags[f])))
#         end
#     end
#     return data
# end


function dict2array(tags::Dict)
    data = []
    for (k, v) in tags
        push!(data, Dict{String, Any}("key" => k, "val" => Dict{String, String}("value" => v)))
    end
    return data
end

function decodeTags(data)
    tags = Dict{String, String}()
    for item in data
        tags[item["key"]] = item["val"]["value"]
    end
    return tags
end

function decodeAnnotations(data)
    annotations = Dict{String, Any}()
    for item in data
        annotations[item["key"]] = item["val"]["value"]
    end
    return annotations
end

