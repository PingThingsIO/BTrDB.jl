# BTrDB.jl

These are the BTrDB Bindings for Julia allowing you painless and productive access to the [Berkeley Tree Database](http://btrdb.io/) (BTrDB). BTrDB is a time series database focusing on blazing speed with respect to univariate time series data at nanosecond scale.

To understand why BTrDB is so fast, see [BTrDB Explained](https://pingthingsio.github.io/BTrDB.jl/latest/man/explained/) in the documentation and feel free to check out the underlying academic paper.

## Installation

At the moment, you will need to install directly from our [GitHub repo](https://github.com/PingThingsIO/BTrDB.jl).

```julia
julia> Pkg.clone("git@github.com:PingThingsIO/BTrDB.jl.git")
INFO: Cloning Package from git://github.com/PingThingsIO/BTrDB.jl.git
Cloning into 'BTrDB.jl'...
```

## Usage

Please see our official [documentation](https://pingthingsio.github.io/BTrDB.jl/latest/) for the latest usage information.  However, to give you a quick taste see the code below.  More interactions such windowing queries, etc. are demonstrated in the docs.

### Create a new stream

```julia
collection = "sensors/electrical"
uuid_token = "33ecd8fe-8942-5bd3-ad9f-b3e8165399ab"
tags = Dict{String, String}(
    "name"      => "pmu_springfield_22",
    "unit"      => "volts"
)
annotations = Dict{String, Any}(
    "phase" => "A",
)

stream = create(uuid_token, collection, tags, annotations)
```

### Insert data

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

### Raw Values Query

To retrieve the raw values in a given range of time you can use the `values` function which accepts a `Stream` object along with the start and end timestamps (`Int64`).  This call will return an array of `RawPoint` objects.

```julia
s = stream_from_uuid(uuid_token)
points = values(s, 1546300802000000000, 1546300804000000000)
```

## TODO

* Support the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface
* Add conversion to [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)
