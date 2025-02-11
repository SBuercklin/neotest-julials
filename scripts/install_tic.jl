using Pkg
Pkg.activate("testitemcontroller"; shared = true)

Pkg.add(;
    url = "https://github.com/julia-vscode/TestItemControllers.jl",
    rev = "main"
)
