const SPECIES_URL = GBIF_URL * "species"
const SPECIES_MATCH_URL = GBIF_URL * "species/match"
const SPECIES_SEARCH_URL = GBIF_URL * "species/search"

const SPECIES_KEYS = (:language, :datasetKey, :sourceId, :name, :offset, :limit)
const SPECIES_MATCH_KEYS = (:rank, :name, :strict, :verbose, :kingdom, :phylum, :class, :order, :family, :genus)
const SPECIES_SEARCH_KEYS = (
    :class, :datasetKey, :facet, :facetMincount, :facetMultiselect, :family, :genus, :habitat,
    :highertaxonKey, :hl, :isExtinct, :issue, :kingdom, :language, :nameType, :nomenclaturalStatus, :order,
    :phylum, :q, :rank, :sourceId, :status, :strict, :threat, :verbose, :offset, :limit
)

const SPECIES_RESULTTYPE = (
    verbatim = (),
    name = (),
    parents = (:language,),
    children = (:language,),
    related = (:language,:datasetKey),
    synonyms = (:language,),
    combinations = (),
    descriptions = (),
    distributions = (),
    media = (),
    references = (),
    speciesProfiles = (),
    vernacularNames = (),
    typeSpecimens = (),
)

"""
    Species

Wrapper object for information returned by [`species`](@ref), [`species_list` ](@ref),
[`species_match` ](@ref) or [`species_search`](@ref) queries. These often are species,
but a more correctly taxa, as it may be e.g. "Aves" for all birds. We use `Species`
for naming consistency with the GBIF API.

Species also serve as rows in [`Table`](@ref), and are converted to rows in a DataFrame
or CSV automatically by the Tables.jl interface.

`Species` properties are accessed with `.`, e.g. `sp.kingdom`.
Note that these queries do not all return all properties, and not all records contain
all properties in any case. Missing properties simply return `missing`.

The possible properties of a `Species` object are:
$(species_properties())
"""
struct Species
    obj::JSON3.Object
end
object(sp::Species) = getfield(sp, :obj)
Species(raw::Union{AbstractString,AbstractVector{UInt8}}) = Species(JSON3.read(raw))


Base.propertynames(sp::Species) = keys(species_properties())
function Base.getproperty(sp::Species, k::Symbol) 
    if k in keys(object(sp)) 
        return convert(species_properties()[k], getproperty(object(sp), k)) 
    else
        k in keys(species_properties()) || error("Species has no field $k")
        return missing
    end
end

Tables.schema(::Species) = Tables.schema(Species)
Tables.schema(::Type{<:Species}) =
    Tables.Schema(keys(species_properties()), values(species_properties()))

Tables.istable(::AbstractVector{Species}) = true
Tables.rowaccess(::AbstractVector{Species}) = true
Tables.schema(::AbstractVector{Species}) = Tables.schema(Species)

"""
    species(key; kw...)
    species(key, resulttype; kw...)

Query the GBIF `species` api, returning a single `Species`.

- `key`: a species key, or `Species` object from another search that a key can be
    obtained from.
- `resulttype`: set this so that instead of a `Species`, `species` will return an
    object in `$(keys(SPECIES_RESULTTYPE))`. The return value will be a raw JSON3.Object`,
    but its `propertynames` can be checked and used to access data.

# Example

Here we find a species with `species_search`, and then obtain the complete record with
`species`.

```julia
julia> using GBIF2
julia> tbl = species_search("Falco punctatus")
20-element GBIF2.Table{GBIF2.Species, JSON3.Array{JSON3.Object, Vector{UInt8}, SubArray{
UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}}}
┌──────────┬──────────┬───────────────┬───────────────┬────────────┬─────────┬──────────
│  kingdom │   phylum │         class │         order │     family │   genus │         ⋯
│  String? │  String? │       String? │       String? │    String? │ String? │         ⋯
├──────────┼──────────┼───────────────┼───────────────┼────────────┼─────────┼──────────
│ Animalia │  missing │          Aves │ Falconiformes │ Falconidae │ missing │ Falco p ⋯
│ Animalia │  missing │          Aves │       missing │ Falconidae │   Falco │ Falco p ⋯
│  missing │  missing │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯
│  missing │ Chordata │       missing │       missing │ Falconidae │   Falco │ Falco p ⋯
│ Animalia │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯
│ Animalia │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯
│  Metazoa │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯
│ Animalia │  missing │       missing │ Falconiformes │ Falconidae │ missing │ Falco p ⋯
│  Metazoa │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯
│    ⋮     │    ⋮     │       ⋮       │       ⋮       │     ⋮      │    ⋮    │         ⋱
└──────────┴──────────┴───────────────┴───────────────┴────────────┴─────────┴──────────
                                                          35 columns and 11 rows omitted

julia> species(tbl[6])
GBIF2.Species({
                   "key": 102091853,
                "nubKey": 2481005,
               "nameKey": 4400647,
               "taxonID": "175650",
               "kingdom": "Animalia",
                "phylum": "Chordata",
                 "order": "Falconiformes",
                "family": "Falconidae",
                 "genus": "Falco",
               "species": "Falco punctatus",
            "kingdomKey": 101683523,
             "phylumKey": 102017110,
              "classKey": 102085317,
              "orderKey": 102091762,
             "familyKey": 102091763,
              "genusKey": 102091765,
            "speciesKey": 102091853,
            "datasetKey": "9ca92552-f23a-41a8-a140-01abaa31c931",
             "parentKey": 102091765,
                "parent": "Falco",
        "scientificName": "Falco punctatus Temminck, 1821",
         "canonicalName": "Falco punctatus",
        "vernacularName": "Mauritius Kestrel",
            "authorship": "Temminck, 1821",
              "nameType": "SCIENTIFIC",
                  "rank": "SPECIES",
                "origin": "SOURCE",
       "taxonomicStatus": "ACCEPTED",
   "nomenclaturalStatus": [],
        "numDescendants": 0,
           "lastCrawled": "2022-10-10T18:15:33.989+00:00",
       "lastInterpreted": "2022-10-10T19:16:16.841+00:00",
                "issues": [
                            "SCIENTIFIC_NAME_ASSEMBLED"
                          ],
               "synonym": false,
                 "class": "Aves"
})
```

## Keyword arguments

- `language`: can be specified for a single argument or with second argument in
    `(:parents, :children, :related, :synonyms)`. 
- `datasetKey`: can be specified, with a second argument `:related`.
"""
function species(sp::Species, args...; kw...)
    query = _bestquery(sp)
    species(last(first(query)), args...; kw...)
end
function species(key::Integer; kw...)
    url = _joinurl(SPECIES_URL, string(key))
    query = _format_query(kw, (:language,))
    request = HTTP.get(url; query)
    return _handle_request(Species, request)
end
function species(key::Integer, resulttype::Symbol; kw...)
    resulttype in keys(SPECIES_RESULTTYPE) || throw(ArgumentError("resulttype $resulttype not in $(keys(SPECIES_RESULTTYPE))"))
    url = _joinurl(SPECIES_URL, string(key), string(subpath))
    query = _format_query(kw, SPECIES_RESULTTYPE[subpath])
    request = HTTP.get(url; query)
    return _handle_request(JSON3.read, request)
end

"""
    species_list(; kw...)
    species_list(key; kw...)
    species_list(key, resulttype; kw...)

Query the GBIF `species_list` api, returning a table of `Species` that exactly
match your query.

# Example

```julia
using GBIF2
species_list(; name="Lalage newtoni")

# output
8-element GBIF2.Table{GBIF2.Species, JSON3.Array{JSON3.Object, Vector{UInt8}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}}}
┌──────────┬──────────┬───────────────┬───────────────┬───────────────┬──────────┬──────────────────┬───────────┬─────────┬──────────┬──────────────┬────────────────┬───────
│  kingdom │   phylum │         class │         order │        family │    genus │          species │       key │  nubKey │  nameKey │      taxonID │ sourceTaxonKey │ king ⋯
│  String? │  String? │       String? │       String? │       String? │  String? │          String? │    Int64? │  Int64? │   Int64? │      String? │         Int64? │      ⋯
├──────────┼──────────┼───────────────┼───────────────┼───────────────┼──────────┼──────────────────┼───────────┼─────────┼──────────┼──────────────┼────────────────┼───────
│ Animalia │ Chordata │          Aves │ Passeriformes │ Campephagidae │ Coracina │ Coracina newtoni │   8385394 │ missing │ 18882488 │ gbif:8385394 │      176651982 │      ⋯
│ Animalia │  missing │          Aves │       missing │ Campephagidae │   Lalage │   Lalage newtoni │ 100144670 │ 8385394 │  5976204 │        06014 │        missing │  128 ⋯
│ Animalia │  missing │          Aves │ Passeriformes │ Campephagidae │  missing │   Lalage newtoni │ 133165079 │ 8385394 │  5976204 │        18380 │        missing │  135 ⋯
│ Animalia │ Chordata │          Aves │ Passeriformes │ Campephagidae │   Lalage │   Lalage newtoni │ 161400685 │ 8385394 │ 18882488 │       895898 │        missing │  134 ⋯
│  missing │  missing │       missing │       missing │       missing │ Bossiaea │   Lalage newtoni │ 165585935 │ missing │ 18882488 │      6924877 │        missing │    m ⋯
│ Animalia │  missing │          Aves │ Passeriformes │ Campephagidae │   Lalage │   Lalage newtoni │ 165923305 │ 8385394 │ 18882488 │        19393 │        missing │  100 ⋯
│ Animalia │ Chordata │          Aves │ Passeriformes │ Campephagidae │   Lalage │   Lalage newtoni │ 168010293 │ 8385394 │  5976204 │       181376 │        missing │  167 ⋯
│ Animalia │ Chordata │ Passeriformes │          Aves │ Campephagidae │   Lalage │   Lalage newtoni │ 176651982 │ 8385394 │ 18882488 │     22706569 │        missing │  202 ⋯
└──────────┴──────────┴───────────────┴───────────────┴───────────────┴──────────┴──────────────────┴───────────┴─────────┴──────────┴──────────────┴────────────────┴───────
```

## Keyword arguments

We use keywords exactly as in the [GBIF api](https://www.gbif.org/developer/species).

You can find keyword enum values with the `[GBIF2.enum](@ref)` function.

$(_keydocs(SPECIES_KEY_DESC, SPECIES_KEYS))
"""
species_list(name::String; kw...) = species_list(; name, kw...)
function species_list(; kw...)
    url = SPECIES_URL
    query = _format_query(kw, SPECIES_KEYS)
    request = HTTP.get(url; query)
    return _handle_request(body -> Table{Species}(query, body), request)
end

"""
    species_match(; kw...)

Query the GBIF `species/match` api, returning the single closest `Species`
using fuzzy search.

The results are not particularly detailed, this can be improved by calling 
`species(res)` on the result of `species_match` to query for the full dataset.

# Example

```julia
using GBIF2
sp = species_match("Lalage newtoni")

# output
GBIF2.Species({
           "usageKey": 8385394,
   "acceptedUsageKey": 2486791,
     "scientificName": "Lalage newtoni (Pollen, 1866)",
      "canonicalName": "Lalage newtoni",
               "rank": "SPECIES",
             "status": "SYNONYM",
         "confidence": 98,
          "matchType": "EXACT",
            "kingdom": "Animalia",
             "phylum": "Chordata",
              "order": "Passeriformes",
             "family": "Campephagidae",
              "genus": "Coracina",
            "species": "Coracina newtoni",
         "kingdomKey": 1,
          "phylumKey": 44,
           "classKey": 212,
           "orderKey": 729,
          "familyKey": 9284,
           "genusKey": 2482359,
         "speciesKey": 2486791,
            "synonym": true,
              "class": "Aves"
})
```

## Keywords

We use keywords exactly as in the [GBIF api](https://www.gbif.org/developer/species).

You can find keyword enum values with the `[GBIF2.enum](@ref)` function.

$(_keydocs(SPECIES_KEY_DESC, SPECIES_MATCH_KEYS))
"""
function species_match end
species_match(name; kw...) = species_match(; name, kw...)
function species_match(; kw...)
    url = SPECIES_MATCH_URL
    query = _format_query(kw, SPECIES_MATCH_KEYS)
    request = HTTP.get(url; query)
    return _handle_request(request) do body
        json = JSON3.read(body)
        if json.matchType == "NONE" 
            @warn "No match for your request, $json"
            nothing
        else
            Species(json)
        end
    end
end

"""
    species_search([q]; kw...)

Query the GBIF `species/search` api, returning many results in a [`GBIF2.Table`](@ref).

# Example

```julia
using GBIF2
sp = species_search("Psittacula eques")

# output
20-element GBIF2.Table{GBIF2.Species, JSON3.Array{JSON3.Object, Vector{UInt8}, SubArray{UInt64, 1,
Vector{UInt64}, Tuple{UnitRange{Int64}}, true}}}
┌──────────┬──────────┬────────────────┬────────────────┬───────────────┬──────────────┬───────────
│  kingdom │   phylum │          class │          order │        family │        genus │          ⋯
│  String? │  String? │        String? │        String? │       String? │      String? │          ⋯
├──────────┼──────────┼────────────────┼────────────────┼───────────────┼──────────────┼───────────
│ Animalia │ Chordata │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯
│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │      missing │          ⋯
│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │   Psitta ⋯
│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │      missing │   Psitta ⋯
│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │      missing │          ⋯
│ Animalia │  missing │        missing │ Psittaciformes │ Psittaculidae │      missing │   Psitta ⋯
│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │   Psitta ⋯
│  missing │  missing │        missing │        missing │       missing │   Psittacula │   Psitta ⋯
│ Animalia │ Chordata │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯
│ Animalia │  missing │           Aves │        missing │   Psittacidae │   Psittacula │   Psitta ⋯
│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │    Psitt ⋯
│ Animalia │ Chordata │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯
│ ANIMALIA │ CHORDATA │ PSITTACIFORMES │           AVES │   PSITTACIDAE │ Alexandrinus │ Alexandr ⋯
│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │    Psitt ⋯
│ Animalia │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │   Psitta ⋯
│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯
│    ⋮     │    ⋮     │       ⋮        │       ⋮        │       ⋮       │      ⋮       │          ⋱
└──────────┴──────────┴────────────────┴────────────────┴───────────────┴──────────────┴───────────
                                                                      35 columns and 4 rows omitted
```

## Keyword arguments

We use keywords exactly as in the [GBIF api](https://www.gbif.org/developer/species).

$(_keydocs(SPECIES_KEY_DESC, SPECIES_SEARCH_KEYS))
"""
function species_search end
species_search(q; kw...) = species_search(; q, kw...)
function species_search(; limit=20, offset=0, kw...)
    url = SPECIES_SEARCH_URL
    if limit > 300
        offsets = offset:300:(limit + offset)
        lastlimit = limit - last(offsets)
        results = species_search(; limit=300, offset, kw...)
        for offset in offsets[begin+1:end-1]
            nextresults = species_search(; limit=300, offset, kw...)
            if length(nextresults) < 300
                results = vcat(results, nextresults)
                @info "$(length(results)) species found, limit was $limit"
                return results
            else
                results = vcat(results, nextresults)
            end
        end
        lastresult = species_search(; limit=lastlimit, offset=last(offsets), kw...)
        return vcat(results, lastresult)
    else
        # Make a single request
        query = _format_query((; limit, offset, kw...), SPECIES_SEARCH_KEYS)
        request = HTTP.get(url; query)
        return _handle_request(body -> Table{Species}(query, body), request)
    end
end

function Base.NamedTuple(species::Species)
    values = map(propertynames(species)) do k
        getproperty(species, k)
    end
    Base.NamedTuple{propertynames(species)}(values)
end
function Base.Dict(species::Species)
    values = map(propertynames(Species)) do k
        getproperty(species, k)
    end
    Dict(propertynames(Species) .=> values)
end

function _bestquery(species::Species)
    for key in (
        :taxonKey, :speciesKey, :genusKey, :familyKey, :orderKey, :classKey, :phylumKey, :kingdomKey,
    )
        key in keys(object(species)) && return [key => getproperty(object(species), key)]
    end
    error("Species has no keys available to use")
end
