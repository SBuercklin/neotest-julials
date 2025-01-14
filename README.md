# `neotest-julials`

Implements the [`neotest`](https://github.com/nvim-neotest/neotest) interface for displaying and running Julia tests via `neotest`.

This package uses `LanguageServer.jl` to identify tests tagged with `@testitem` to display. This means it will not function without a recent release of `LanguageServer.jl` which supports the `"julia/publishTests"`

## Installation and Usage

To install and use `neotest-julials`, just install the package using your Neovim package manager of choice, and then add `neotest-julials` as an adapter in your `neotest` configuration.

An example installation using `lazy.nvim` could look like:

```lua
{
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        {"sbuercklin/neotest-julials", config = true} -- config = true is necessary!
    },
    opts = function(_)
        return {
            adapters = {
                require("neotest-julials"),
            },
        }
        return opts
    end,
}
```

Note that you must **also** configure your Julia Language Server to support `julia/publishTests` at startup.

The following entry must be merged with your `julials` configuration, otherwise the test detection will not operate:

```lua
julials_config = {
    init_options = { julialangTestItemIdentification = true },
}
```

## Status

`neotest-julials` is a work in progress. Right now, it only supports test discovery. In the future, it should support running + retrieving test results for display in Neovim using the standard `neotest` machinery. 
