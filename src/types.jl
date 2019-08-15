using Base64


"""
    RawPoint

A point of data representing a single position within a time series. Each
point contains a read-only time and value attribute.

**Constructors**

```julia
RawPoint(time::Int64, value::Float64)
RawPoint(data::Dict{String,Any})
RawPoint(time, value)
```

**Arguments**

* time : the time (`Int64`) of a single value in the time series (in nanoseconds since the Unix epoch)
* value : the value (`Int64`) of a time series at a single point in time

**Notes**

The `RawPoint` constructors are used internally by calls such as `values`.

"""
struct RawPoint
    time::Int64
    value::Float64
end


"""
    StatPoint

An aggregated data point representing a summary or rollup of one or more
points of data within a single time series.

This aggregation point provides for the min, mean, max, count, and standard
deviation of all data values it spans. It is returned by windowing queries
such as windows or aligned_windows.

**Constructors**

```julia
StatPoint(time::Int64, min::Float64, mean::Float64, max::Float64,
          count::Int64, stddev::Float64)
StatPoint(data::Dict{String,Any})
StatPoint(time, min, mean, max, count, stddev)
```

**Arguments**

* time : a `Int64` for the time span represented by the aggregated values (in nanoseconds since the Unix epoch)
* min : a `Float64` representing the minimum value of points in this window
* mean : a `Float64` representing the average value of points in this window
* max : a `Float64` representing the maximum value of points in this window
* count : a `Int64` for the number of real values in this window
* stddev : a `Float64` representing the standard deviation of point values in this window

**Notes**

The `StatPoint` constructors are used internally by aggregation calls such as `windows` and `aligned_windows`.
"""
struct StatPoint
    time::Int64
    min::Float64
    mean::Float64
    max::Float64
    count::Int64
    stddev::Float64
end


"""
    Stream

An object that represents a specific time series stream in the BTrDB database.

**Constructors**

```julia
Stream(uuid::String, name::String, collection::String, tags::Dict{String,String},
       annotations::Dict{String,Any}, version::Int64, propertyVersion::Int64)
Stream(data::Dict{String,Any})
Stream(uuid, name, collection, tags, annotations, version, propertyVersion)
```

**Arguments**

* uuid : a `String` of the stream's unique identifier
* name : a `String` of the stream's friendly name
* collection : a `String` of the stream's collection (path) in the stream hierarchy
* tags : a `Dict{String,String}` of the stream's (internal use) metadata
* annotations : a `Dict{String,Any}` of the stream's public metadata
* version : a `Int64` that acts as a monotonically increasing version of the data
* propertyVersion : a `Int64` that acts as a monotonically increasing version of the metadata

**Notes**

The `Stream` constructors are used internally by any calls that will return Stream objects.
In general, this is unlikely to be used by end users but is still provided in the public API.

"""
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


"""
    RawPoint

    A point of data representing a single position within a time series. Each point contains a read-only time and value attribute.
"""
function RawPoint(data::Dict{String,Any})
    return RawPoint(parse(Int64, data["time"]), data["value"])
end

"""
StatPoint

An aggregated data point representing a summary or rollup of one or more points of data within a single time series.

This aggregation point provides for the min, mean, max, count, and standard deviation of all data values it spans. It is returned by windowing queries such as windows or aligned_windows.
"""
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
