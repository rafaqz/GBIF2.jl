# GBIF2

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://rafaqz.github.io/GBIF2.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://rafaqz.github.io/GBIF2.jl/dev/)
[![Build Status](https://github.com/rafaqz/GBIF2.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/rafaqz/GBIF2.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/rafaqz/GBIF2.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/rafaqz/GBIF2.jl)

GBIF2 attempts to follow the GBIF api as closecly as possible, and to be as
complete as possible.

Its main design features are:
- multiple results for both species and occurrences are Tables.jl compatible,
  and can be converted to a `DataFrame` or writted directly using CSV.jl and similar packages.
- all enum keys are checked before querying.
- A `limit` above `300` are allowed, unlike in the original API, by making
  multiple reuests and joining the results.
- for larger workloads, download requests are handled with gbif.org
  account authentication.

## A quick example

```julia
julia> using GBIF2, DataFrames

# Basic species match with `species_match`:
julia> sp = species_match("Lalage newtoni");

julia> sp.species
"Coracina newtoni"

julia> sp.synonym
true

julia> sp.vernacularName
missing

# Det a more detail object with `species`:
julia> sp_detailed = species(sp);

julia> sp_detailed.vernacularName
"Reunion Cuckooshrike"

# Get the first 2000 occurrences for the species from 2000 to 2020, on reunion:
julia> oc = occurrence_search(sp;
           limit=2000, country=:RE, hasCoordinate=true, year=(2000,2020)
       ) |> DataFrame
2000×83 DataFrame
  Row │ decimalLongitude  decimalLatitude  year    month   day
      │ Float64?          Float64?         Int64?  Int64?  Int64?
──────┼────────────────────────────────────────────────────────────
    1 │          55.5085         -21.0192    2020       1      14
    2 │          55.4133         -20.928     2020       1      23
    3 │          55.4133         -20.928     2020       1      16
    4 │          55.5085         -21.0192    2020       1      14
    5 │          55.4123         -21.0184    2020       1      13
    6 │          55.4133         -20.928     2020       1      28
    7 │          55.4133         -20.928     2020       1      16
  ⋮   │        ⋮                 ⋮           ⋮       ⋮       ⋮
 1994 │          55.4133         -20.928     2017      10      29
 1995 │          55.4123         -21.0184    2017      10      25
 1996 │          55.4123         -21.0184    2017      10      25
 1997 │          55.4123         -21.0184    2017      10      17
 1998 │          55.4123         -21.0184    2017      10      25
 1999 │          55.4123         -21.0184    2017      10      25
 2000 │          55.4123         -21.0184    2017      10      25
```
