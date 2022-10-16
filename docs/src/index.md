```@meta
CurrentModule = GBIF2
```

# GBIF2

Documentation for [GBIF2](https://github.com/rafaqz/GBIF2.jl).

```@docs
GBIF2
```

```@index
```

There are a number of ways to query the GBIF database for species, 
returning different numbers of results and amounts of data.

`Species` objects and queries correspond closely to the [GBIF
species api](https://www.gbif.org/developer/species).

```@docs
Species
species
species_list
species_match
species_search
```

`Occurrence` objects and queries correspond closely to the [GBIF
occurrence api](https://www.gbif.org/developer/occurrence).

```
Occurrence
occurrence
occurrence_search
occurrence_request
occurrence_download
occurrence_count
occurrence_inventory
```
