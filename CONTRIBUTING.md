We welcome contributions to Finch, and follow the [Julia contributing
guidelines](https://github.com/JuliaLang/julia/blob/master/CONTRIBUTING.md).  If
you use or want to use Finch and have a question or bug, please do file a
[Github issue](https://github.com/willow-ahrens/Finch.jl/issues)!  If you want
to contribute to Finch, please first file an issue to double check that there is
interest from a contributor in the feature.

## Utilities

Finch include several scripts that can be executed directly, e.g. `runtests.jl`.
These scripts are all named `run*.jl` and they all have local [Pkg
environments](https://pkgdocs.julialang.org/v1/getting-started/#Getting-Started-with-Environments).
The scripts include convenience headers to automatically use their respective
environments, so you won't need to worry about `--project=.` flags, etc.

## Documentation

The `/docs` directory includes Finch documentation in `/src`, and a built
website in `/build`. You can build the website with `./docs/runmake.jl`. You can
run doctests with `./docs/rundoctests.jl`, and fix doctests with `./docs/runfix.jl`.

## Testing

All pull requests should pass continuous integration testing before merging.
The test suite has a few options, which are accessible through running the test
suite directly as `./tests/runtests.jl`.

Finch compares compiler output against reference versions. If you run the test
suite directly you can pass the `--overwrite` flag to tell the test suite to
overwrite the reference.  Because the reference output depends on the system
word size, you'll need to generate reference output for 32-bit and 64-bit builds
of Julia to get Finch to pass tests. The easiest way to do this is to run each
32-bit or 64-bit build of Julia on a system that supports it. You can
[Download](https://julialang.org/downloads/) multiple builds yourself or use
[juliaup](https://github.com/JuliaLang/juliaup) to manage multiple versions.
Using juliaup, it might look like this:

```
julia +release~x86 tests/runtests.jl --overwrite
julia +release~x64 tests/runtests.jl --overwrite
```

The test suite takes a while to run. You can filter to only run a selection of
test suites by specifying them as positional arguments, e.g.

```
./tests/runtests.jl constructors conversions representation
```

This information is summarized with `./tests/runtests.jl --help`