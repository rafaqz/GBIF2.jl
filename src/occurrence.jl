const OCCURRENCE_URL = GBIF_URL * "occurrence"
const OCCURRENCE_SEARCH_URL = GBIF_URL * "occurrence/search"
const OCCURRENCE_DOWNLOAD_URL = GBIF_URL * "occurrence/download"

const OCCURRENCE_SEARCH_KEYS = (:q, :basisOfRecord, :catalogNumber, :classKey, :collectionCode, :continent, :coordinateUncertaintyInMeters, :country, :crawlId, :datasetId, :datasetKey, :datasetName, :decimalLatitude, :decimalLongitude, :depth, :elevation, :establishmentMeans, :eventDate, :eventId, :familyKey, :gadmGid, :gadmLevel0Gid, :gadmLevel1Gid, :gadmLevel2Gid, :gadmLevel3Gid, :genusKey, :geometry, :hasCoordinate, :hasGeospatialIssue, :geoDistance, :identifiedBy, :identifiedByID, :institutionCode, :issue, :kingdomKey, :lastInterpreted, :license, :locality, :mediaType, :modified, :month, :networkKey, :occurrenceId, :occurrenceStatus, :orderKey, :organismId, :organismQuantity, :organismQuantityType, :otherCatalogNumbers, :phylumKey, :preparations, :programme, :projectId, :protocol, :publishingCountry, :publishingOrg, :recordNumber, :recordedBy, :recordedByID, :relativeOrganismQuantity, :repatriated, :sampleSizeUnit, :sampleSizeValue, :samplingProtocol, :scientificName, :speciesKey, :stateProvince, :subgenusKey, :taxonKey, :typeStatus, :verbatimScientificName, :verbatimTaxonId, :waterBody, :year, :facet, :facetMincount, :facetMultiselect, :paging, :offset, :limit)

const OCCURRENCE_SUBPATHS = (:fragment, :verbatim)

const OCCURRENCE_COUNT_INVENTORY = (
    basisOfRecord = (),
    countries = :publishingCountry,
    datasets = (:country, :taxonKey),
    publishingCountry = (:publishingCountry,),
    year = (:year,)
)

const OCCURRENCE_SEARCH_RETURNTYPE = (
    catalogNumber   = "Search that returns matching catalog numbers. Table are ordered by relevance.",
    collectionCode  = "Search that returns matching collection codes. Table are ordered by relevance.",
    occurrenceId    = "Search that returns matching occurrence identifiers. Table are ordered by relevance.",
    recordedBy      = "Search that returns matching collector names. Table are ordered by relevance.",
    recordNumber    = "Search that returns matching record numbers. Table are ordered by relevance.",
    institutionCode = "Search that returns matching institution codes. Table are ordered by relevance.",
)


"""
    Occurrence

Wrapper object for information returned about an occurrence by [`occurrence`](@ref)
and [`occurrence_search`](@ref) queries. `Occurrence` also serves as rows in `Table`,
and is converted to rows in a DataFrame or CSV automatically by the Tables.jl interface.

Occurrence properties are accessed with `.`, e.g. `oc.country`.
Note that these queries do not all return all properties, and not all records contain
all properties in any case. Missing properties simply return `missing`.

The possible properties of an `Occurrence` object are:
$(keys(occurrence_properties()))
"""
struct Occurrence
    obj::JSON3.Object
end

object(oc::Occurrence) = getfield(oc, :obj)
Occurrence(raw::Union{AbstractString,AbstractVector{UInt8}}) = Occurrence(JSON3.read(raw))

Base.propertynames(sp::Occurrence) = keys(occurrence_properties())
function Base.getproperty(oc::Occurrence, k::Symbol)
    if k in keys(object(oc))
        prop = getproperty(object(oc), k)
        # Convert JSON objects to json strings
        if prop isa JSON3.Object
            JSON3.write(prop)
        elseif prop isa JSON3.Array{<:JSON3.Object}
            JSON3.write.(prop)
        else
            convert(occurrence_properties()[k], prop)
        end
    else
        k in keys(occurrence_properties()) || error("Occurrence has no field $k")
        return missing
    end
end

_schema(::Type{<:Occurrence}) =
    Tables.Schema(keys(occurrence_properties()), values(occurrence_properties()))

Tables.istable(::AbstractVector{Occurrence}) = true
Tables.rowaccess(::AbstractVector{Occurrence}) = true
Tables.schema(::AbstractVector{Occurrence}) = _schema(Occurrence)

"""
    occurrence(key; [returntype])
    occurrence(occurrence::Occurrence; [returntype])
    occurrence(datasetKey, occurrenceID; [returntype])

Retrieve a single [`Occurrence`](@ref) by its `key`, by `datasetKey` and `occurrenceID`
or by passing in an `Occurrence` object.

# Keyword

- `returntype` modifies the return value, and can be `:fragment` or `:verbatim`.

# Example

```julia
using GBIF2
sp = species_match("Falco punctatus")
ocs = occurrence_search(sp)
oc = occurrence(ocs[1]; returntype=:verbatim)

# output
GBIF2.Occurrence({
                                              "key": 3556750430,
                                       "datasetKey": "4fa7b334-ce0d-4e88-aaae-2e0c138d049e",
                                 "publishingOrgKey": "e2e717bf-551a-4917-bdc9-4fa0f342c530",
                                  "installationKey": "7182d304-b0a2-404b-baba-2086a325c221",
                                "publishingCountry": "MU",
                                         "protocol": "DWC_ARCHIVE",
                                      "lastCrawled": "2022-03-02T17:41:33.833+00:00",
                                       "lastParsed": "2022-09-08T14:55:01.342+00:00",
                                          "crawlId": 15,
                                       "extensions": {},
   "http://rs.gbif.org/terms/1.0/publishingCountry": "MU",
             "http://rs.tdwg.org/dwc/terms/country": "Mauritius",
      "http://rs.tdwg.org/dwc/terms/collectionCode": "EBIRD",
               "http://rs.tdwg.org/dwc/terms/order": "Falconiformes",
                "http://rs.tdwg.org/dwc/terms/year": "2021",
      "http://rs.tdwg.org/dwc/terms/vernacularName": "Mauritius Kestrel",
            "http://rs.tdwg.org/dwc/terms/locality": "Ebony Forest Reserve Chamarel",
       "http://rs.tdwg.org/dwc/terms/basisOfRecord": "HumanObservation",
              "http://rs.tdwg.org/dwc/terms/family": "Falconidae",
               "http://rs.tdwg.org/dwc/terms/month": "07",
     "http://rs.tdwg.org/dwc/terms/decimalLatitude": "-20.436033",
      "http://rs.tdwg.org/dwc/terms/taxonConceptID": "avibase-D1069C26",
      "http://rs.tdwg.org/dwc/terms/scientificName": "Falco punctatus",
          "http://rs.tdwg.org/dwc/terms/recordedBy": "obsr2637790",
       "http://rs.tdwg.org/dwc/terms/stateProvince": "Black River",
              "http://rs.tdwg.org/dwc/terms/phylum": "Chordata",
              "http://rs.gbif.org/terms/1.0/gbifID": "3556750430",
                 "http://rs.tdwg.org/dwc/terms/day": "15",
               "http://rs.tdwg.org/dwc/terms/genus": "Falco",
             "http://rs.tdwg.org/dwc/terms/kingdom": "Animalia",
              "http://purl.org/dc/terms/identifier": "OBS1201437854",
               "http://rs.tdwg.org/dwc/terms/class": "Aves",
     "http://rs.tdwg.org/dwc/terms/individualCount": "1",
     "http://rs.tdwg.org/dwc/terms/specificEpithet": "punctatus",
        "http://rs.tdwg.org/dwc/terms/occurrenceID": "URN:catalog:CLO:EBIRD:OBS1201437854",
       "http://rs.tdwg.org/dwc/terms/catalogNumber": "OBS1201437854",
    "http://rs.tdwg.org/dwc/terms/decimalLongitude": "57.37246",
     "http://rs.tdwg.org/dwc/terms/institutionCode": "CLO",
       "http://rs.tdwg.org/dwc/terms/geodeticDatum": "WGS84",
    "http://rs.tdwg.org/dwc/terms/occurrenceStatus": "PRESENT"
})
```
"""
occurrence(oc::Occurrence; kw...) = occurrence(oc.key; kw...)
function occurrence(key; returntype=nothing)
    url = _joinurl(OCCURRENCE_URL, key)
    if isnothing(returntype)
        request = HTTP.get(url)
        return _handle_request(Occurrence, request)
    else
        returntype in OCCURRENCE_SUBPATHS || throw(ArgumentError("$returntype not in $OCCURRENCE_SUBPATHS"))
        request = HTTP.get(_joinurl(url, returntype))
        return _handle_request(JSON3.read, request)
    end
end
function occurrence(datasetKey, occurrenceID; returntype=nothing)
    url = _joinurl(OCCURRENCE_URL, datasetKey, occurrenceID)
    if isnothing(returntype)
        request = HTTP.get(url)
        return _handle_request(Occurrence, request)
    else
        returntype in OCCURRENCE_SUBPATHS || throw(ArgumentError("$returntype not in $OCCURRENCE_SUBPATHS"))
        request = HTTP.get(_joinurl(url, returntype))
        return _handle_request(JSON3.read, request)
    end
end

"""
    occurrence_search(species::Species; kw...)
    occurrence_search([q]; kw...)
    occurrence_search(q, returntype; limit...)

Search for occurrences, returning a `Table{Occurrence}` table.

# Example

Here we find a species with `species_match`, and then retrieve all the
occurrences with `occurrence_search`.

```julia
julia> 
using GBIF2

julia> 
sp = species_match("Falco punctatus");

julia> 
ocs = occurrence_search(sp; continent=:AFRICA, limit=1000)
[ Info: 522 occurrences found, limit was 1000
522-element GBIF2.Table{GBIF2.Occurrence, Vector{JSON3.Object}}
┌──────────────────┬─────────────────┬────────┬────────┬────────┬────────────
│ decimalLongitude │ decimalLatitude │   year │  month │    day │  kingdom  ⋯
│         Float64? │        Float64? │ Int64? │ Int64? │ Int64? │  String?  ⋯
├──────────────────┼─────────────────┼────────┼────────┼────────┼────────────
│          missing │         missing │   2012 │      8 │     18 │ Animalia  ⋯
│          missing │         missing │   2010 │      1 │     29 │ Animalia  ⋯
│          57.2452 │        -20.2239 │   2009 │     10 │     26 │ Animalia  ⋯
│          57.2452 │        -20.2239 │   2009 │     11 │      5 │ Animalia  ⋯
│          57.2452 │        -20.2239 │   2009 │     11 │      5 │ Animalia  ⋯
│          57.2452 │        -20.2239 │   2009 │     11 │      4 │ Animalia  ⋯
│          57.2452 │        -20.2239 │   2009 │     11 │      5 │ Animalia  ⋯
│          57.2452 │        -20.2239 │   2009 │     11 │      4 │ Animalia  ⋯
│          57.7667 │          -19.85 │   2007 │      6 │     19 │ Animalia  ⋯
│          57.7667 │          -19.85 │   2007 │      6 │     19 │ Animalia  ⋯
│          57.7667 │          -19.85 │   2007 │      6 │     19 │ Animalia  ⋯
│          57.7667 │          -19.85 │   2007 │      6 │     19 │ Animalia  ⋯
│          57.7667 │          -19.85 │   2007 │      6 │     19 │ Animalia  ⋯
│          57.7667 │          -19.85 │   2007 │      6 │     19 │ Animalia  ⋯
│          57.7667 │          -19.85 │   2007 │      6 │     19 │ Animalia  ⋯
│        ⋮         │        ⋮        │   ⋮    │   ⋮    │   ⋮    │    ⋮      ⋱
└──────────────────┴─────────────────┴────────┴────────┴────────┴────────────
                                              78 columns and 507 rows omitted
```

# Arguments

- `q`: a search query.
- `species`: if the first value is a species, search keywords will be retrieved from it.
- `returntype`: modify the returntype, with a `Symbol` from :
$(_argdocs(OCCURRENCE_SEARCH_RETURNTYPE))

# Keywords

We use parameters exactly as in the [GBIF api](https://www.gbif.org/developer/species).

You can find keyword enum values with the `[GBIF2.enum](@ref)` function.

GBIF range queries work by putting values in a `Tuple`, e.g. `elevation=(10, 100)`.

$(_keydocs(OCCURRENCE_KEY_DESC, keys(OCCURRENCE_KEY_DESC)))
"""
function occurrence_search end
function occurrence_search(species::Species; kw...)
    occurrence_search(; q=_bestquery(species)[1][2], kw...)
end
occurrence_search(q; kw...) = occurrence_search(; q, kw...)
function occurrence_search(; returntype=nothing, limit=20, offset=0, kw...)
    if !isnothing(returntype)
        allowed_rt = keys(OCCURRENCE_SEARCH_RETURNTYPE)
        returntype in allowed_rt || throw(ArgumentError("$returntype not in $allowed_rt"))
        url = _joinurl(OCCURRENCE_SEARCH_URL, returntype)
        query = _format_query((; limit, kw...), keys(OCCURRENCE_KEY_DESC))
        request = HTTP.get(url; query)
        return _handle_request(JSON3.read, request)
    end
    if limit > 300
        offsets = offset:300:(limit + offset)
        lastlimit = limit - last(offsets)
        results = occurrence_search(; limit=300, offset, kw...)
        for offset in offsets[begin+1:end-1]
            nextresults = occurrence_search(; limit=300, offset, kw...)
            if length(nextresults) < 300
                results = vcat(results, nextresults)
                @info "$(length(results)) occurrences found, limit was $limit"
                return results
            else
                results = vcat(results, nextresults)
            end
        end
        lastresult = occurrence_search(; limit=lastlimit, offset=last(offsets), kw...)
        return vcat(results, lastresult)
    else
        # Make a single request
        url = OCCURRENCE_SEARCH_URL
        query = _format_query((; limit, offset, kw...), keys(OCCURRENCE_KEY_DESC))
        request = HTTP.get(url; query)
        return _handle_request(body -> Table{Occurrence}(query, body), request)
    end
end

"""
    occurrence_count(species::Species; kw...)
    occurrence_count(; kw...)

Count the number of occurrences for a taxon.

# Example

```
juila> sp = species_match("Pteropus niger");

juila> occurrence_count(sp)
559
```

# Keywords

- `taxonKey`: is the most useful key when a `Species` is not passed.

Occurrence counts have a complicated schema of allowed keyword combinations.
You can access these from the GBIF api using `GBIF2.occurrence_count_schema()`.
"""
function occurrence_count end
function occurrence_count(species::Species; kw...)
    return occurrence_count(; taxonKey=_bestquery(species)[1][2], kw...)
end
function occurrence_count(; kw...)
    url = _joinurl(OCCURRENCE_URL, "count")
    query = _format_query(kw, keys(OCCURRENCE_KEY_DESC))
    request = HTTP.get(url; query)
    return _handle_request(body -> JSON3.read(body, Int64), request)
end

"""
    occurrence_inventory(type::Symbol; kw...)

Return the number of occurrences for a taxon based on 
certain criteria. The return value is a JSON3.jl object.

# Example

```
julia> country_counts = occurrence_inventory(:countries)
JSON3.Object{Vector{UInt8}, Vector{UInt64}} with 252 entries:
  :UNITED_STATES  => 816855696
  :CANADA         => 133550183
  :FRANCE         => 119683053
  :SWEDEN         => 116451484
  :AUSTRALIA      => 115239040
  :UNITED_KINGDOM => 108417142
  :NETHERLANDS    => 85750415
  :SPAIN          => 54804973
  :DENMARK        => 49334935
  :GERMANY        => 49290658
  :NORWAY         => 48337823
  :FINLAND        => 36970838
  :BELGIUM        => 35064346
  :SOUTH_AFRICA   => 33185318
  :INDIA          => 32071907
  :MEXICO         => 26295593
  :BRAZIL         => 24558941
  :COSTA_RICA     => 21103286
  :COLOMBIA       => 20143253
  :SWITZERLAND    => 17727317
  :PORTUGAL       => 17688228
  ⋮               => ⋮

julia> country_counts.INDIA
32071907
```

# Keywords

- `type`: inventory accross categories, with additional keywords from: 
`$OCCURRENCE_COUNT_INVENTORY`

Occurrence counts have a complicated schema of allowed keyword combinations.
You can access these from the GBIF api using `occurrence_count_schema()`.
"""
function occurrence_inventory(returntype; kw...)
    returntype in keys(OCCURRENCE_COUNT_INVENTORY) || throw(ArgumentError("$returntype not in $OCCURRENCE_COUNT_INVENTORY"))
    url = _joinurl(OCCURRENCE_URL, "counts", returntype)
    query = _format_query(kw, OCCURRENCE_COUNT_INVENTORY[returntype])
    request = HTTP.get(url; query)
    return _handle_request(JSON3.read, request)
end

# Not exported
"""
    occurrence_count_schema()

Return the raw schema of allowed keyword/parameter combinations
to be used with `occurrence_count`.
"""
function occurrence_count_schema()
    url = _joinurl(OCCURRENCE_URL, "count", "schema")
    request = HTTP.get(url; )
    return first.(_handle_request(request) do body
        JSON3.read(body, Vector{NamedTuple{(:dimensions,),Tuple{Vector{NamedTuple{(:key,:type)}}}}})
    end)
end

const LAST_DOWNLOAD = Base.RefValue{String}("")

"""
    occurrence_request(sp::Species; kw...)
    occurrence_request(; kw...)

Request an occurrence download, returning a token that will later
provide a download url. You can call `occurrence_download(token)`
when it is ready. Prior to that, you will get 404 errors.

# Example

Here we request to dowload all of the occurrences of
the Common Myna, _Acridotheres tristis_.

```
julia> sp = species_match("Acridotheres tristis");

julia> occurrence_count(sp)
1936341
julia> token = occurrence_request(sp, username="my_gbif_username")
```

This will prompt for your password, and either throw an error
or return a value for the `token` to use later in `occurrence_download`.

If you forgot to store the token and your session is still open,
you can simply use `occurrence_download()` to download the most
recent request.

# Keywords

- `username`: String username for a gbif.org account
- `password`: String password for a gbif.org account. The password
    will be entered in the REPL if this keyword is not used.
- `type`: choose from an `:and` or `:or` query.

Allowed query keywords are:
`$(keys(occurrence_request_parameters()))`

# Modifiers

Prameter values can modify the kind of match by using a pair:
`elevation = :lessThan => 100`, or using julia Fix2 operators like
`elevation = >(100)`.

| Pair key             | Fix2  | Description                                                                      |
| :------------------  | ----: | :------------------------------------------------------------------------------- |
| :equals              | ==(x) | equality comparison                                                              |
| :lessThan            |  <(x) | is less than                                                                     |
| :lessThanOrEquals    | <=(x) | is less than or equals                                                           |
| :greaterThan         | =>(x) | is greater than                                                                  |
| :greaterThanOrEquals | >=(x) | greater than or equals                                                           |
| :in                  | in(x) | specify multiple values to be compared                                           |
| :not                 | !=(x) | logical negation                                                                 |
| :and                 |  &(x) | logical AND (conjuction)                                                         |
| :or                  |  |(x) | logical OR (disjunction)                                                         |
| :like                |       | search for a pattern, ? matches one character, * matches zero or more characters |

# To pass instead of a value:

|:isNull    | has an empty value    |
|:isNotNull | has a non-empty value |
"""
function occurrence_request end
function occurrence_request(species::Species; kw...)
    occurrence_request(; _bestquery(species)..., kw...)
end
function occurrence_request(;
    username, password=nothing, notificationAddresses=nothing, format="SIMPLE_CSV", geoDistance=nothing, type="and", kw...
)
    notificationAddresses = if isnothing(notificationAddresses)
        (;)
    elseif notificationAddresses isa AbstractString
        (; notificationAddresses=[notificationAddresses], sendNotification=true)
    elseif notificationAddresses isa AbstractVector
        (; notificationAddresses, sendNotification=true)
    end
    url = _joinurl(OCCURRENCE_DOWNLOAD_URL, "request")
    params = occurrence_request_parameters()
    query = pairs(_format_query(kw, keys(params)))
    predicates = NamedTuple[_predicate(params, k, v) for (k, v) in query]
    if !isnothing(geoDistance)
        keys(geoDistance) == (:latitude, :longitude, :distance) ||
            throw(ArgumentError("geoDistance must have keys `(:latitude, :longitude, :distance)`, has `$(keys(geoDistance))`"))
        push!(predicates, (; type=:geoDistance, geoDistance...))
    end
    obj = (;
        format,
        creator=username,
        notificationAddresses...,
        predicate = (;
            type,
            predicates,
       )
    )
    if isnothing(password)
        x = Base.getpass("Enter your GBIF password")
        password = read(x, String)
    end
    auth = Base64.base64encode(username * ":" * password)
    headers = [
        "Authorization" => "Basic $auth",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
    ]
    json = JSON3.write(obj)

    # `json` Looks something like:
    #   "creator": "userName",
    #   "notificationAddresses": [
    #     "userEmail@example.org"
    #   ],
    #   "sendNotification": true,
    #   "format": "SIMPLE_CSV",
    #   "predicate": {
    #     "type": "and",
    #     "predicates": [
    #       {
    #         "type": "equals",
    #         "key": "BASIS_OF_RECORD",
    #         "value": "PRESERVED_SPECIMEN"
    #       },
    #       {
    #         "type": "in",
    #         "key": "COUNTRY",
    #         "values": [
    #           "KW",
    #           "IQ",
    #           "IR"
    #         ]
    #       }
    #     ]
    #   }
    # }

    response = HTTP.post(url, headers, json)
    token = JSON3.read(response.body)
    return token
end

"""
    occurrence_download([key::String]; [filename])

Download the data for an occurrence key returned by `occurrence_request`,
or without arguments download the last result of `occurrence_request`.

Note that `occurrence_download` depends on gbif.org preparing the
download. Prior to it will give a 404 error as the page will not be found.

The `filename` keyword can be used to name the resulting file.

# Example

Request all the common mynor birds below 100m of elevation:

```
sp = species_match("Acridotheres tristis");
token = occurrence_request(sp, username="my_gbif_username", elevation=<(100))
write("mydownloadtoken", string(token)) # save it just in case
# wait for your download to be prepared
# If you need to, read the token again:
token = readlines("mydownloadtoken")[1]
# And download it
filename = GBIF2.occurrence_download(token)
```
"""
function occurrence_download(token=LAST_DOWNLOAD[]; filename=string(token, ".zip"))
    token = string(token)
    url = _joinurl(OCCURRENCE_DOWNLOAD_URL, "request", token)
    return HTTP.download(url, filename)
end

function _predicate(params, key, val)
    if val in (:isNull, :isNotNull)
        (type=val, key=params[key])
    else
        (type=_valtype(val), key=params[key], value=_val(val))
    end
end

_val(v) = v
_val(v::Base.Fix2) = v.x
_val(v::Pair) = v[2]
_valtype(v::Pair) = v[1]
_valtype(v) = "equals"
_valtype(v::Base.Fix2{typeof(==)}) = "equals"
_valtype(v::Base.Fix2{typeof(!=)}) = "not"
_valtype(v::Base.Fix2{typeof(>)}) = "greaterThan"
_valtype(v::Base.Fix2{typeof(|)}) = "or"
_valtype(v::Base.Fix2{typeof(&)}) = "and"
_valtype(v::Base.Fix2{typeof(<)}) = "lessThan"
_valtype(v::Base.Fix2{typeof(>=)}) = "greaterThanOrEquals"
_valtype(v::Base.Fix2{typeof(<=)}) = "lessThanOrEquals"

