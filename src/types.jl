using Base64


# A point of data representing a single position within a time series. Each
# point contains a read-only time and value attribute.
struct RawPoint
    time::Int64
    value::Float64
end


# An aggregated data point representing a summary or rollup of one or more
# points of data within a single time series.
#
# This aggregation point provides for the min, mean, max, count, and standard
# deviation of all data values it spans. It is returned by windowing queries
# such as windows or aligned_windows.
struct StatPoint
    time::Int64
    min::Float64
    mean::Float64
    max::Float64
    count::Int64
    stddev::Float64
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


function StatPoint(data::Dict{String,Any})
    if typeof(data["stddev"]) == String
        stddev = NaN
    else
        stddev = data["stddev"]
    end
    return StatPoint(
        parse(Int64, data["time"]),
        data["min"],
        data["mean"],
        data["max"],
        parse(Int64, data["count"]),
        stddev
    )
end


###############################################################################
# Module Only Utility Functions
###############################################################################

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
