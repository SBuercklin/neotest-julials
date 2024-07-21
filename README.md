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
        "sbuercklin/neotest-julials"
    },
    config = function ()
        require("neotest").setup({
          adapters = {
            require("neotest-julials"),
          },
        })
    end
}
```

## Status

`neotest-julials` is a work in progress. Right now, it only supports test discovery. In the future, it should support running + retrieving test results for display in Neovim using the standard `neotest` machinery. 
