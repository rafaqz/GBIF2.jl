```@meta
CurrentModule = GBIF2
```

# GBIF2

Documentation for [GBIF2](https://github.com/rafaqz/GBIF2.jl).

```@index
```

## Overview

```@docs
GBIF2
```

There are a number of ways to query the GBIF database for species, 
returning different numbers of results and amounts of data.

## Species

`Species` objects and queries correspond closely to the [GBIF
species api](https://www.gbif.org/developer/species).

```@docs
Species
species_match
species
species_search
species_list
```

## Occurrence

`Occurrence` objects and queries correspond closely to the [GBIF
occurrence api](https://www.gbif.org/developer/occurrence).

```@docs
Occurrence
occurrence_search
occurrence
occurrence_request
occurrence_download
occurrence_count
occurrence_count_schema
occurrence_inventory
```

# Low level

Species and occurrences are return in a generalised `Table` object.

```@docs
GBIF2.Table
GBIF2.enum
```
