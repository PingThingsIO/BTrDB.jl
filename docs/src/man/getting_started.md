# Getting Started

## Installation

At the moment, you will need to install directly from our [GitHub repo](https://github.com/PingThingsIO/BTrDB.jl).

```julia
julia> Pkg.clone("git@github.com:PingThingsIO/BTrDB.jl.git")
INFO: Cloning Package from git://github.com/PingThingsIO/BTrDB.jl.git
Cloning into 'BTrDB.jl'...
```

## Connecting to BTrDB

Connection to the server is handled transparently through the use of environmental variables.

Specifically, you will need to set `BTRDB_ENDPOINTS` and `BTRDB_API_KEY` which should have been provided to you by the server administrators.

We would suggest putting these values in your shell profile (such as `.bashrc` or `.zshrc`).  You can set these values on Unix-like operating systems with the following commands

```bash
export BTRDB_ENDPOINTS=api.myallocation.predictivegrid.com
export BTRDB_API_KEY=FAC53575B9FB949C544091CCC
```

