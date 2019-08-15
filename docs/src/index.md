# BTrDB.jl

Welcome to the BTrDB.jl documentation.  We provide Julia access to the Berkeley
Tree Database (BTrBD) along with some select convenience methods.

BTrDB is a very, very fast timeseries database.  Specifically, it is a time partitioned,
version annotated, clustered solution for high density univariate data.  It's also
incredibly easy to use.

Information on specific versions of these bindings can be found on the [Release page](https://github.com/PingThingsIO/BTrDB.jl/releases).

## Package Manual

```@contents
Pages = [
    "man/getting_started.md",
    "man/explained.md",
    "man/concepts.md",
]
Depth = 2
```

## API

Only exported (i.e. available for use without `BTrDB.` qualifier after loading
the BTrDB.jl package with `using BTrDB`) types and functions are considered
a part of the public API of the BTrDB.jl package. In general all such objects
are documented in this manual (in case some documentation is missing
please kindly report an issue [here](https://github.com/PingThingsIO/BTrDB.jl/issues/new)).

Please be warned that while Julia allows you to access internal functions or types of BTrDB.jl
these can change without warning between versions of BTrDB.jl. In particular
it is not safe to directly access fields of types that are a part of public API
of the BTrDB.jl package using e.g. the `info` function. Whenever some
operation on fields of defined types is considered allowed an appropriate exported
function should be used instead.

```@contents
Pages = ["lib/types.md", "lib/functions.md"]
Depth = 2
```

## Index

```@index
Pages = ["lib/types.md", "lib/functions.md"]
```