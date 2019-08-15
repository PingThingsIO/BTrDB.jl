
module BTrDB

using HTTP, JSON

export
    RawPoint, Stream,
    collections, streams,
    refresh, create, obliterate, settags, setannotations, # stream management functions
    nearest, earliest, latest, values, windows, aligned_windows, # data retrieval functions
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


"""
    collections()

Returns an array of all collection strings
"""
function collections()
    return collections("")
end


"""
    collections(starts_with::String)

Returns an array of all collection strings that start with a given String
"""
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


"""
    streams(collection::String)

Returns an Array of `Stream` objects found with the supplied collection.
"""
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

"""
    create(uuid::String, collection::String, tags::Dict{String, String}, annotations::Dict{String, Any})

Creates a new stream on the server.
"""
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

"""
    refresh(uuid::String)

Returns a new `Stream` object with the latest metadata from the server.
"""
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

"""
    refresh(stream::Stream)

Returns a new `Stream` object with the latest metadata from the server.
"""
refresh(stream::Stream) = refresh(stream.uuid)


"""
    stream_from_uuid(uuid::String)

Returns a new `Stream` object with the latest metadata from the server.
Alias for `refresh(uuid::String)`
"""
stream_from_uuid(uuid::String) = refresh(uuid)

"""
    obliterate(uuid::String)

Deletes a `Stream` with a given UUID from the server permanently.
"""
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

"""
    obliterate(stream::Stream)

Deletes a `Stream` from the server permanently.
"""
obliterate(stream::Stream) = obliterate(stream.uuid)


"""
    flush(uuid::String)

Forces the database to commit buffered data.  This function is generally
not needed by end users.
"""
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

"""
    flush(stream::Stream)

Forces the database to commit buffered data.  This function is generally
not needed by end users.
"""
flush(stream::Stream) = flush(stream.uuid)


"""
    settags(stream::Stream, tags::Dict{String, String})

Overwrites existing tags.

**Notes**

Tags are used internally by the system and are not generally meant to be
manipulated by end users.

If you would like to add your own custom metadata, please use annotations.
"""
function settags(stream::Stream, tags::Dict{String, String})
    url = join([BASEURL, "setstreamtags"], "/")
    payload = Dict(
        "uuid" => encodeUUID(stream.uuid),
        "expectedPropertyVersion" => stream.propertyVersion,
        "tags" => dict2array(tags),
        "collection" => stream.collection
    )

    response = apicall(url, JSON.json(payload))
    result = JSON.parse(response)
    checkstat(result)

    return refresh(stream)
end

"""
    setannotations(stream::Stream, annotations::Dict{String, Any})

Overwrites existing annotations.

**Notes**

Stream annotations are provided so that you may store Stream related custom
metadata.

You cannot delete annotations at this time though this will change in a
future update.
"""
function setannotations(stream::Stream, annotations::Dict{String, Any})
    url = join([BASEURL, "setstreamannotations"], "/")
    payload = Dict(
        "uuid" => encodeUUID(stream.uuid),
        "expectedPropertyVersion" => stream.propertyVersion,
        "changes" => dict2array(annotations),
    )

    response = apicall(url, JSON.json(payload))
    result = JSON.parse(response)
    checkstat(result)

    return refresh(stream)
end


###############################################################################
# Stream Data Retrieval Functions
###############################################################################

"""
    nearest(stream::Stream, time::Int64, version::Int=0, backward::Bool=false)

Finds the closest point in the stream to a specified time.

Return the point nearest to the specified `time` in nanoseconds since
Epoch in the stream with `version` while specifying whether to search
forward or backward in time. If `backward` is false, the returned point
will be >= `time`. If backward is true, the returned point will be <
`time`. The version of the stream used to satisfy the query is returned.

**Arguments**

* stream : The `Stream` object to search
* time : The `Int64` time (in nanoseconds since Epoch) to search near
* version : `Int64` version of the stream to use in search
* backward : `boolean` (true) to search backwards from time, else false for forward

"""
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

"""
    earliest(stream::Stream, version::Int=0)

Returns the first point of data in the stream.

**Arguments**

* stream : The `Stream` object to search
* version : `Int64` version of the stream to use in search
"""
earliest(stream::Stream, version::Int=0) = nearest(stream, MINIMUM_TIME, version, false)


"""
    latest(stream::Stream, version::Int=0)

Returns last point of data in the stream.

**Arguments**

* stream : The `Stream` object to search
* version : `Int64` version of the stream to use in search
"""
latest(stream::Stream, version::Int=0) = nearest(stream, MAXIMUM_TIME, version, true)


"""
    values(stream::Stream, start::Int64, stop::Int64, version::Int=0)

Read raw values from BTrDB between time [start, stop) in nanoseconds.

RawValues queries BTrDB for the raw time series data points between
`start` and `end` time, both in nanoseconds since the Epoch for the
specified stream `version`.

**Arguments**

* start : The start time (`Int64`) in nanoseconds for the range to be queried (inclusive)
* stop : The end time (`Int64`) in nanoseconds for the range to be queried (exclusive)
* version : `Int64` version of the stream to use when querying data

**Notes**

Note that the raw data points are the original values at the sensor's
native sampling rate (assuming the time series represents measurements
from a sensor). This is the lowest level of data with the finest time
granularity. In the tree data structure of BTrDB, this data is stored in
the vector nodes.
"""
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

"""
    windows(stream::Stream, start::Int64, stop::Int64, width::Int, depth::Int, version::Int=0)

Read arbitrarily-sized windows of data from BTrDB.  StatPoint objects
will be returned representing the data for each window.

**Arguments**

* start : The start time (`Int64`) in nanoseconds for the range to be queried (inclusive)
* stop : The end time (`Int64`) in nanoseconds for the range to be queried (exclusive)
* version : `Int64` version of the stream to use when querying data
* width :  the number (`Int`) of nanoseconds in each window, subject to the depth parameter.
* depth : The precision of the window duration as a power of 2 in nanoseconds. E.g 30 would make the window duration accurate to roughly 1 second

**Notes**

Windows returns arbitrary precision windows from BTrDB. It is slower
than AlignedWindows, but still significantly faster than RawValues. Each
returned window will be `width` nanoseconds long. `start` is inclusive,
but `end` is exclusive (e.g if end < start+width you will get no
results). That is, results will be returned for all windows that start
at a time less than the end timestamp. If (`end` - `start`) is not a
multiple of width, then end will be decreased to the greatest value less
than end such that (end - start) is a multiple of `width` (i.e., we set
end = start + width * floordiv(end - start, width). The `depth`
parameter is an optimization that can be used to speed up queries on
fast queries. Each window will be accurate to 2^depth nanoseconds. If
depth is zero, the results are accurate to the nanosecond. On a dense
stream for large windows, this accuracy may not be required. For example
for a window of a day, +- one second may be appropriate, so a depth of
30 can be specified. This is much faster to execute on the database
side.
"""
function windows(stream::Stream, start::Int64, stop::Int64, width::Int, depth::Int, version::Int=0)
    url = join([BASEURL, "windows"], "/")
    payload = Dict(
        "uuid" => encodeUUID(stream.uuid),
        "start" => string(start),
        "end" => string(stop),
        "width" => string(width),
        "depth" => depth,
        "versionMajor" => version
    )
    response = apicall(url, JSON.json(payload))
    points = StatPoint.(parse_api_results(response, "values"))

    return points
end


"""
    aligned_windows(stream::Stream, start::Int64, stop::Int64, pointwidth::Int, version::Int=0)

Read statistical aggregates of windows of data from BTrDB.

Query BTrDB for aggregates (or roll ups or windows) of the time series
with `version` between time `start` (inclusive) and `end` (exclusive) in
nanoseconds. Each point returned is a statistical aggregate of all the
raw data within a window of width 2**`pointwidth` nanoseconds. These
statistical aggregates currently include the mean, minimum, and maximum
of the data and the count of data points composing the window.

Note that `start` is inclusive, but `end` is exclusive. That is, results
will be returned for all windows that start in the interval [start, end).
If end < start+2^pointwidth you will not get any results. If start and
end are not powers of two, the bottom pointwidth bits will be cleared.
Each window will contain statistical summaries of the window.
Statistical points with count == 0 will be omitted.

**Arguments**

* start : The start time (`Int64`) in nanoseconds for the range to be queried (inclusive)
* stop : The end time (`Int64`) in nanoseconds for the range to be queried (exclusive)
* pointwidth : the number of ns between data points (2**pointwidth)
* version : `Int64` version of the stream to use when querying data

**Notes**

As the window-width is a power-of-two, it aligns with BTrDB internal
tree data structure and is faster to execute than `windows()`.
"""
function aligned_windows(stream::Stream, start::Int64, stop::Int64, pointwidth::Int, version::Int=0)
    url = join([BASEURL, "alignedwindows"], "/")
    payload = Dict(
        "uuid" => encodeUUID(stream.uuid),
        "start" => string(start),
        "end" => string(stop),
        "pointWidth" => string(pointwidth),
        "versionMajor" => version
    )
    response = apicall(url, JSON.json(payload))
    points = StatPoint.(parse_api_results(response, "values"))

    return points

end


###############################################################################
# Stream Data Management Functions
###############################################################################

"""
    insert(uuid::String, data::Array{Pair{Int64, Float64},1})

Insert new data in the form (time, value) into the series.

Inserts a list of new (time, value) tuples into the series. The tuples
in the list need not be sorted by time. If the arrays are larger than
appropriate, this function will automatically chunk the inserts. As a
consequence, the insert is not necessarily atomic, but can be used with
a very large array.

**Arguments**

* uuid : a `String` for the stream's unique identifier
* data : an `Array` of `Pair` objects representings points where the first pair item is the time (`Int64`) and the second item is the value (`Float64`)
"""
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

"""
    insert(stream::Stream, data::Array{Pair{Int64, Float64},1})

Insert new data in the form (time, value) into the series.

Inserts a list of new (time, value) tuples into the series. The tuples
in the list need not be sorted by time. If the arrays are larger than
appropriate, this function will automatically chunk the inserts. As a
consequence, the insert is not necessarily atomic, but can be used with
a very large array.

**Arguments**

* stream : the `Stream` to use for data insertion
* data : an `Array` of `Pair` objects representings points where the first pair item is the time (`Int64`) and the second item is the value (`Float64`)
"""
insert(stream::Stream, data::Array{Pair{Int64, Float64},1}) = insert(stream.uuid, data)


"""
    delete(uuid::String, start::Int64, stop::Int64)

"Delete" all points between `start` (inclusive) and `end` (exclusive),
both in nanoseconds. As BTrDB has persistent multiversioning, the
deleted points will still exist as part of an older version of the
stream.

**Arguments**

* uuid : the `String` UUID of the stream to use for data deletion
* start : the start time (`Int64`) in nanoseconds for the range to be deleted (inclusive)
* stop : the end time (`Int64`) in nanoseconds for the range to be deleted (exclusive)
"""
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

"""
    delete(stream::Stream, start::Int64, stop::Int64)

"Delete" all points between `start` (inclusive) and `end` (exclusive),
both in nanoseconds. As BTrDB has persistent multiversioning, the
deleted points will still exist as part of an older version of the
stream.

**Arguments**

* stream : the `Stream` to use for data deletion
* start : the start time (`Int64`) in nanoseconds for the range to be deleted (inclusive)
* stop : the end time (`Int64`) in nanoseconds for the range to be deleted (exclusive)
"""
delete(stream::Stream, start::Int64, stop::Int64) = delete(stream.uuid, start, stop)

end # module


