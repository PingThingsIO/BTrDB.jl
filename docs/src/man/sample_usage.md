# Sample Usage

## Managing Streams

### Create a New Stream

To create a new stream so that you can insert points, you may use the `create` function.  There is some metadata that will be required including the UUID, collection, tags, and annotations.  Annotations is the only argument that is not required for creating a new stream.

```julia
collection = "zoo/animals"
uuid_token = "33ecd8fe-8942-5bd3-ad9f-b3e8165399ab"
tags = Dict{String, String}(
    "name"      => "liger",
    "unit"      => "animal"
)
annotations = Dict{String, Any}(
    "phase" => "A"
)

s = create(uuid_token, collection, tags, annotations)
```

### Delete a Stream

Assuming you have the appropriate permissions, deleting a stream is straightforward using the `obliterate` function as shown below.

```julia
uuid_token = "33ecd8fe-8942-5bd3-ad9f-b3e8165399ae"
obliterate(uuid_token)
```

Many functions will allow you to use either the UUID or a Stream object as the input such as the example below:

```julia
s = create(uuid_token, collection, tags, annotations)
obliterate(s)
```

## Querying for Streams

### Collections

You can think of collections as the path to your individual streams.  Mutliple streams can live in a given collection and you can easily query for all available collections using the `collections` function.

```julia
collections("")
2989-element Array{Any,1}:
 "USGS/GEOMAG/Boulder"
 "USGS/GEOMAG/Barrow"
 "USGS/GEOMAG/Honolulu"
 ...
```

### Streams

We can query for all the streams in a collection using the `streams` function.

```julia
streams("USGS")
102-element Array{BTrDB.Stream,1}:
 BTrDB.Stream("12d7b1e7-a38e-45c0-8959-d3231b254cab", "BOU_Z", "USGS/GEOMAG/Boulder", Dict("distiller"=>"","name"=>"BOU_Z","unit"=>"nanotesla","ingress"=>""), Dict{String,Any}("element"=>"Z","elevation"=>"1682","latitude"=>"40.137","longitude"=>"254.764","orientation"=>"HDZF","reported"=>"HDZF","source"=>"United States Geological Survey","station"=>"Boulder"), 0, 0)
 ...
```

Although if you already have the UUID, you can retrieve that stream directly using the `refresh` or the `stream_from_uuid` function (which is aliased to `refresh`).  `refresh` will take either a UUID string or a Stream object.

```julia
refresh("12d7b1e7-a38e-45c0-8959-d3231b254cab")
BTrDB.Stream("12d7b1e7-a38e-45c0-8959-d3231b254cab", "BOU_Z", "USGS/GEOMAG/Boulder", Dict("distiller"=>"","name"=>"BOU_Z","unit"=>"nanotesla","ingress"=>""), Dict{String,Any}("element"=>"Z","elevation"=>"1682","latitude"=>"40.137","longitude"=>"254.764","orientation"=>"HDZF","reported"=>"HDZF","source"=>"United States Geological Survey","station"=>"Boulder"), 0, 0)
```

## Managing Stream Data

### Inserts

The BTrDB bindings expect an array of `Pair` objects for insertion into a stream.  The first element of the pair is the `Int64` timestamp in nanoseconds and the last element is the `Float64` value.

```julia
data = [
    Pair(1546300801000000000, 1.0),
    Pair(1546300802000000000, 2.0),
    Pair(1546300803000000000, 3.0)
]
s = stream_from_uuid(uuid_token)
insert(s, data)
```

## Querying Stream Data

### Raw Values Query

To retrieve the raw values in a given range of time you can use the `values` function which accepts a `Stream` object along with the start and end timestamps (`Int64`).  This call will return an array of `RawPoint` objects.

```julia
s = stream_from_uuid(uuid_token)
points = values(s, 1546300802000000000, 1546300804000000000)
```

### Windows Query

To return windowed results, you may choose to use the `windows` function.  As in similar libraries, this call will provide a summary of values within the provided window size, `width`, in nanoseconds.  `StatPoint` objects are returned which contain `time`, `min`, `mean`, `max`, `count`, and `stddev` attributes to describe the aggregated time series points.  The `depth` argument determines the level of accuracy that is provided as smaller numbers will travel further down into the BTrDB tree data structure (see the `BTrDB Explained` page for more info).

```julia
start = 1546300800000000000
stop  = 1546300808000000000
width = 2000000000
depth = 20
points = windows(s, start, stop, width, depth)
```

### Aligned Windows Query

Similar to the `windows` query but with better performance, there is an `aligned_windows` function in which the width of the window is determined by the `pointwidth` argument.  Window size will be determined as a power of 2 using pointwidth as the exponent (2^pointwidth).  If you don't need precise start/stop times to your windows, then this function is often a better choice than the `windows` query.

Just like the `windows` function, this call will return an array of `StatPoint` objects.  These objects contain `time`, `min`, `mean`, `max`, `count`, and `stddev` attributes to describe the aggregated time series points.

```julia
s = stream_from_uuid(uuid_token)
start = 1546300800000000000
stop =  1546300808000000000
pointwidth = 20
points = aligned_windows(s, start, stop, pointwidth)
```
