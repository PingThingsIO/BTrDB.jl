
module BTrDB

using HTTP, JSON

export
    RawPoint, Stream,
    collections, streams,
    refresh, create, obliterate,  # stream management functions
    values, nearest, earliest, latest,  # data retrieval functions
    insert, delete, flush  # data management functions

###############################################################################
# Includes
###############################################################################

include("exceptions.jl")
include("types.jl")
include("utility.jl")

###############################################################################
# Module Variables & Constants
###############################################################################

APIKEY = ENV["BTRDB_API_KEY"]
ENDPOINTS = ENV["BTRDB_ENDPOINTS"]
BASEURL = "https://" * join([string.(split(ENDPOINTS, ":")[1]), "v5"], "/")


###############################################################################
# Status Related
###############################################################################

# intentionally not exported
function info()
    url = join([BASEURL, "info"], "/")
    response = apicall(url, "{}")
    data = JSON.parse(response)

    if data["stat"] != nothing
        if haskey(data["stat"], "code")
            throw(BTrDBException(data["stat"]["message"]))
        end
        throw(BTrDBException("unknown error occurred"))
    end

    return data
end


###############################################################################
# Query for Stream or Collections
###############################################################################

function collections()
    return collections("")
end

function collections(starts_with::String)
    label = "collections"
    url = join([BASEURL, "listcollections"], "/")
    payload = "{\"prefix\": \"$starts_with\"}"
    payload = Dict(
        "prefix" => starts_with
    )

    response = apicall(url, JSON.json(payload))
    return parse_api_results(response, label)
end

function streams(collection::String)

    label = "results"
    url = join([BASEURL, "lookupstreams"], "/")

    payload = Dict(
        "collection" => collection,
        "isCollectionPrefix" => true,
        "tags" => [],
        "annotations" => [],
    )

    response = apicall(url, JSON.json(payload))

    return [Stream(s) for s in parse_api_results(response, label)]
end


###############################################################################
# Stream Management Functions
###############################################################################

function create(uuid::String, collection::String, tags::Dict{String, String}, annotations::Dict{String, Any})

    url = join([BASEURL, "create"], "/")
    payload = Dict(
        "uuid" => encodeUUID(uuid),
        "collection" => collection,
        "tags" => dict2array(tags),
        "annotations" => dict2array(annotations)
    )

    response = apicall(url, JSON.json(payload))
    return refresh(uuid)
end

function refresh(uuid::String)
    url = join([BASEURL, "streaminfo"], "/")
    payload = Dict(
        "uuid" => encodeUUID(uuid),
        "omitVersion" => false,
        "omitDescriptor" => false
    )
    response = apicall(url, JSON.json(payload))
    data = JSON.parse(response)

    if data["stat"] != nothing
        if haskey(data["stat"], "code")
            throw(BTrDBException(data["stat"]["message"]))
        end
        throw(BTrDBException("unknown error occurred"))
    end

    s = Stream(data["descriptor"])
    s.version = parse(Int64, data["versionMajor"])
    s.propertyVersion = parse(Int64, data["descriptor"]["propertyVersion"])
    return s
end

refresh(stream::Stream) = refresh(stream.uuid)


function obliterate(uuid::String)
    url = join([BASEURL, "obliterate"], "/")
    payload = Dict(
        "uuid" => encodeUUID(uuid)
    )
    response = apicall(url, JSON.json(payload))
    data = JSON.parse(response)

    if data["stat"] != nothing
        if haskey(data["stat"], "code")
            throw(BTrDBException(data["stat"]["message"]))
        end
        throw(BTrDBException("unknown error occurred"))
    end
end

obliterate(stream::Stream) = obliterate(stream.uuid)

function flush(uuid::String)
    url = join([BASEURL, "flush"], "/")
    payload = Dict(
        "uuid" => encodeUUID(uuid)
    )
    response = apicall(url, JSON.json(payload))
    data = JSON.parse(response)

    if data["stat"] != nothing
        if haskey(data["stat"], "code")
            throw(BTrDBException(data["stat"]["message"]))
        end
        throw(BTrDBException("unknown error occurred"))
    end
end

flush(stream::Stream) = flush(stream.uuid)


###############################################################################
# Stream Data Retrieval Functions
###############################################################################

function values(stream::Stream, start::Int64, stop::Int64, version::Int=0)
    url = join([BASEURL, "rawvalues"], "/")
    payload = Dict(
        "uuid" => encodeUUID(stream.uuid),
        "start" => string(start),
        "end" => string(stop),
        "versionMajor" => string(version)
    )
    response = apicall(url, JSON.json(payload))
    points = RawPoint.(parse_api_results(response, "values"))

    return points
end

function nearest(stream::Stream, time::Int64, version::Int=0, backward::Bool=false)
    url = join([BASEURL, "nearest"], "/")

    payload = Dict(
        "uuid" => encodeUUID(stream.uuid),
        "time" => string(time),
        "backward" => backward,
        "versionMajor" => stream.version
    )
    response = apicall(url, JSON.json(payload))
    result = JSON.parse(response)
    checkstat(result)

    points = RawPoint(result["value"])
    return points
end

earliest(stream::Stream, version::Int=0) = nearest(stream, MINIMUM_TIME, version, false)
latest(stream::Stream, version::Int=0) = nearest(stream, MAXIMUM_TIME, version, true)


###############################################################################
# Stream Data Management Functions
###############################################################################

function insert(uuid::String, data::Array{Pair{Int64, Float64},1})
    objs = [Dict("time" => ii[1], "value" => ii[2]) for ii in data]

    url = join([BASEURL, "insert"], "/")
    payload = Dict(
        "uuid" => encodeUUID(uuid),
        "sync" => true,
        "values" => objs
    )
    response = apicall(url, JSON.json(payload))
    result = JSON.parse(response)
    checkstat(result)

    return result["versionMajor"]
end

insert(stream::Stream, data::Array{Pair{Int64, Float64},1}) = insert(stream.uuid, data)


function delete(uuid::String, start::Int64, stop::Int64)

    url = join([BASEURL, "delete"], "/")
    payload = Dict(
        "uuid" => encodeUUID(uuid),
        "start" => string(start),
        "end" => string(stop)
    )
    response = apicall(url, JSON.json(payload))
    result = JSON.parse(response)
    checkstat(result)

    return result["versionMajor"]
end

delete(stream::Stream, start::Int64, stop::Int64) = delete(stream.uuid, start, stop)

end # module


