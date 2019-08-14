
module BTrDB

using HTTP, JSON

export collections, streams, values

include("exceptions.jl")
include("types.jl")
include("utility.jl")

APIKEY = ENV["BTRDB_API_KEY"]
ENDPOINTS = ENV["BTRDB_ENDPOINTS"]
BASEURL = "https://" * join([string.(split(ENDPOINTS, ":")[1]), "v5"], "/")

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

function values(stream::Stream, start::Int64, stop::Int64)
    url = join([BASEURL, "rawvalues"], "/")
    payload = Dict(
        "uuid" => encodeUUID(stream.uuid),
        "start" => string(start),
        "end" => string(stop),
        "versionMajor" => "0"
    )
    response = apicall(url, JSON.json(payload))
    points = RawPoint.(parse_api_results(response, "values"))

    return points
end


end # module


