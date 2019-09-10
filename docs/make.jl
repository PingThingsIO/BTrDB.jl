push!(LOAD_PATH,"../src/")

using Documenter, BTrDB

if Base.HOME_PROJECT[] !== nothing
    Base.HOME_PROJECT[] = abspath(Base.HOME_PROJECT[])
end


makedocs(
    # options
    modules = [BTrDB],
    doctest = false,
    clean = false,
    sitename = "BTrDB.jl",
    format = Documenter.HTML(),
    pages = Any[
        "Introduction" => "index.md",
        "User Guide" => Any[
            "Getting Started" => "man/getting_started.md",
            "BTrDB Explained" => "man/explained.md",
            "Concepts" => "man/concepts.md",
            "Sample Usage" => "man/sample_usage.md",
        ],
        "API" => Any[
            "Types" => "lib/types.md",
            "Functions" => "lib/functions.md",
        ]
    ]
)

