push!(LOAD_PATH,"../src/")

using Documenter, BTrDB

makedocs(modules=[BTrDB], sitename="BTrDB Documentation")