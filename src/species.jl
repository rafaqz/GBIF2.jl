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
Tables.schema(::AbstractVector{Species}) = Tables.schema(Occurrence)

"""
    species(key; kw...)
    species(key, resulttype; kw...)

Query the GBIF `species` api, returning a single `Species`.

- `key`: a key 
- `resulttype`: instead of a `Species`, return an object in `$(keys(SPECIES_RESULTTYPE))`. 
    The return value will be a raw JSON3.Object`, but its `propertynames` can be 
    checked and used to access data.

## Keyword arguments

- `language`: can be specified for a single argument or with second argument in
    `(:parents, :children, :related, :synonyms)`. 
- `datasetKey`: can be specified with a second argumen `:related`.
"""
function species(sp::Species, args...; kw...)
    query = _bestquery(sp)
    species(last(first(query)), args...; kw...)
end
function species(key::Int; kw...)
    url = _joinurl(SPECIES_URL, string(key))
    query = _format_query(kw, (:language,))
    request = HTTP.get(url; query)
    return _handle_request(Species, request)
end
function species(key::Int, resulttype::Symbol; kw...)
    resulttype in keys(SPECIES_RESULTTYPE) || throw(ArgumentError("resulttype $resulttype not in $(keys(SPECIES_RESULTTYPE))"))
    url = _joinurl(SPECIES_URL, string(key), string(subpath))
    query = _format_query(kw, SPECIES_RESULTTYPE[subpath])
    request = HTTP.get(url; query)
    return _handle_request(JSON3.read, request)
end

"""
    species(; kw...)
    species(key; kw...)
    species(key, resulttype; kw...)

Query the GBIF `species` api, returning a list of `Species`.

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

Query the GBIF `species/match` api, returning the single closest `Species`.

`match` uses fuzzy search.

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

Query the GBIF `species/search` api, returning many results in a table.

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
