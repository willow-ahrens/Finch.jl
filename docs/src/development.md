# Development Guide

We welcome contributions to Finch! Before you start, please double-check in a
[Github issue](https://github.com/willow-ahrens/Finch.jl/issues) that there is
interest from a contributor in moderating your potential pull request.

## Testing

All pull requests should pass continuous integration testing before merging.
For more information about running tests (including filtering test suites or
updating the reference output), run the test script directly:

```
    julia tests/runtests.jl --help
```