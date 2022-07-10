const OCCURRENCE_URL = GBIF_URL * "occurrence"
const OCCURRENCE_SEARCH_URL = GBIF_URL * "occurrence/search"
const OCCURRENCE_DOWNLOAD_URL = GBIF_URL * "occurrence/download"

const OCCURRENCE_SEARCH_KEYS = (:q, :basisOfRecord, :catalogNumber, :classKey, :collectionCode, :continent, :coordinateUncertaintyInMeters, :country, :crawlId, :datasetId, :datasetKey, :datasetName, :decimalLatitude, :decimalLongitude, :depth, :elevation, :establishmentMeans, :eventDate, :eventId, :familyKey, :gadmGid, :gadmLevel0Gid, :gadmLevel1Gid, :gadmLevel2Gid, :gadmLevel3Gid, :genusKey, :geometry, :hasCoordinate, :hasGeospatialIssue, :geoDistance, :identifiedBy, :identifiedByID, :institutionCode, :issue, :kingdomKey, :lastInterpreted, :license, :locality, :mediaType, :modified, :month, :networkKey, :occurrenceId, :occurrenceStatus, :orderKey, :organismId, :organismQuantity, :organismQuantityType, :otherCatalogNumbers, :phylumKey, :preparations, :programme, :projectId, :protocol, :publishingCountry, :publishingOrg, :recordNumber, :recordedBy, :recordedByID, :relativeOrganismQuantity, :repatriated, :sampleSizeUnit, :sampleSizeValue, :samplingProtocol, :scientificName, :speciesKey, :stateProvince, :subgenusKey, :taxonKey, :typeStatus, :verbatimScientificName, :verbatimTaxonId, :waterBody, :year, :facet, :facetMincount, :facetMultiselect, :paging, :offset, :limit)

const INVENTORY_KEYS = (
    basisOfRecord = (),
    countries = :publishingCountry,
    datasets = (:country, :taxonKey),
    publishingCountry = (:publishingCountry,),
    year = (:year,)
)

const OCCURRENCE_SUBPATHS = (:fragment, :verbatim, Symbol(""))

"""
    Occurrence

Holds a single occurrence.
"""
struct Occurrence
    obj::JSON3.Object
end
object(oc::Occurrence) = getfield(oc, :obj)
Occurrence(raw::Union{AbstractString,AbstractVector{UInt8}}) = Occurrence(JSON3.read(raw))

Base.propertynames(sp::Occurrence) = keys(occurrence_properties())
function Base.getproperty(oc::Occurrence, k::Symbol)
    if k in keys(object(oc))
        return convert(occurrence_properties()[k], getproperty(object(oc), k))
    else
        k in keys(occurrence_properties()) || error("Occurrence has no field $k")
        return missing
    end
end

Tables.schema(::Occurrence) = Tables.schema(Occurrence)
Tables.schema(::Type{<:Occurrence}) =
    Tables.Schema(keys(occurrence_properties()), values(occurrence_properties()))

Tables.istable(::AbstractVector{Occurrence}) = true
Tables.rowaccess(::AbstractVector{Occurrence}) = true
Tables.schema(::AbstractVector{Occurrence}) = Tables.schema(Occurrence)

"""
    occurrence(key; [criteria])
    occurrence(datasetKey, occurrenceID; [criteria])

Retrieve a single occurrence.

`criteria` can be `:fragment` or `:verbatim`.
"""
function occurrence(key; criteria=Symbol(""))
    criteria in OCCURRENCE_SUBPATHS || throw(ArgumentError("$criteria not in $OCCURRENCE_SUBPATHS"))
    url = _joinurl(OCCURRENCE_URL, key, criteria)
    request = HTTP.get(url)
    return _handle_request(Occurrence, request)
end
function occurrence(datasetKey, occurrenceID; criteria=Symbol(""))
    criteria in OCCURRENCE_SUBPATHS || throw(ArgumentError("$criteria not in $OCCURRENCE_SUBPATHS"))
    url = _joinurl(OCCURRENCE_URL, datasetKey, occurrenceID, criteria)
    request = HTTP.get(url)
    return _handle_request(Occurrence, request)
end

const OCCURRENCE_SEARCH_RETURNTYPE = (
    catalogNumber   = "Search that returns matching catalog numbers. Results are ordered by relevance.",
    collectionCode  = "Search that returns matching collection codes. Results are ordered by relevance.",
    occurrenceId    = "Search that returns matching occurrence identifiers. Results are ordered by relevance.",
    recordedBy      = "Search that returns matching collector names. Results are ordered by relevance.",
    recordNumber    = "Search that returns matching record numbers. Results are ordered by relevance.",
    institutionCode = "Search that returns matching institution codes. Results are ordered by relevance.",
)

"""
    occurrence_search(species::Species; kw...)
    occurrence_search([q]; kw...)
    occurrence_search(q, returntype; limit...)

Search for occurrences, returning a `Result{Occurrence}` table.

# Arguments

- `q`: a search query.
- `species`: if the first value is a species, search keywords will be retrieved from it.
- `returntype`: modify the returntype, with a `Symbol` from :
$(_argdocs(OCCURRENCE_SEARCH_RETURNTYPE))

# Keywords

We use parameters exactly as in the [GBIF api](https://www.gbif.org/developer/species).

GBIF range queries work by putting values in a `Tuple`, e.g. `elevation=(10, 100)`.

$(_keydocs(OCCURRENCE_KEY_DESC, keys(OCCURRENCE_KEY_DESC)))
"""
occurrence_search(q; kw...) = occurrence_search(; q, kw...)
function occurrence_search(; limit=20, offset=0, kw...)
    url = OCCURRENCE_SEARCH_URL
    if limit > 300
        offsets = offset:300:(limit + offset)
        lastlimit = limit - last(offsets)
        mostresults = [occurrence_search(; limit=300, offset, kw...) for offset in offsets[begin:end-1]]
        lastresult = occurrence_search(; limit=lastlimit, offset=last(offsets), kw...)
        return vcat(mostresults..., lastresult)
    else
        # Make a single request
        query = _format_query((; limit, offset, kw...), keys(OCCURRENCE_KEY_DESC))
        request = HTTP.get(url; query)
        return _handle_request(body -> Results{Occurrence}(query, body), request)
    end
end
function occurrence_search(species::Species; kw...)
    query = _bestquery(species)
    isnothing(query) && error("Species has no keys to search occurrences with")
    return occurrence_search(; query..., kw...)
end
function occurrence_search(q, returntype::Symbol; limit=20)
    allowed_rt = keys(OCCURRENCE_SEARCH_RETURNTYPE)
    returntype in allowed_rt || throw(ArgumentError("$returntype not in $allowed_rt"))
    url = _joinurl(OCCURRENCE_SEARCH_URL, returntype)
    query = _format_query((; q, limit), (:q, :limit))
    request = HTTP.get(url; query)
    return _handle_request(body -> Results{Occurrence}(query, body), request)
end

"""
    occurrence_count(; kw...)
    occurrence_count(inventory; kw...)

If the `inventory` argument is use, invetory accross all groups will be returned.
The category for grouping can be chosen from `$INVENTORY_KEYS`.


We use parameters exactly as in the [GBIF api](https://www.gbif.org/developer/species).

$(_keydocs(OCCURRENCE_KEY_DESC, keys(OCCURRENCE_KEY_DESC)))
"""
function occurrence_count(; kw...)::Int
    url = _joinurl(OCCURRENCE_URL, "count")
    query = _format_query(kw, keys(OCCURRENCE_KEY_DESC))
    request = HTTP.get(url; query)
    return _handle_request(body -> JSON3.read(body, Int), request)
end
function occurrence_count(inventory::Symbol; kw...)
    inventory in keys(INVENTORY_KEYS) || throw(ArgumentError("$inventory not in $INVENTORY_KEYS"))
    url = _joinurl(OCCURRENCE_URL, "counts", inventory)
    query = _format_query(kw, INVENTORY_KEYS[inventory])
    request = HTTP.get(url; query)
    return _handle_request(body -> JSON3.read(body, Int), request)
end

const LAST_DOWNLOAD = Base.RefValue{String}("")

"""
    occurrence_request(; kw...)

Request an occurrence download, returning a token that will later
provide a download url. You can call `occurrence_download(token)`
when it is ready. Prior to that, you will get 404 errors.

Prameter values can modify the kind of match by using a pair:
`elevation = :lessThan => 100`, or using julia Fix2 operators like
`elevation = >(100)`.

# Possible modifiers

| Pair key             | Fix2  | Description                                                                      | 
| :------------------  | :---- | :------------------------------------------------------------------------------- |
| :equals              | ==(x) | equality comparison                                                              |
| :lessThan            |  <(x) | is less than                                                                     |
| :lessThanOrEquals    | <=(x) | is less than or equals                                                           |
| :greaterThan         | =>(x) | is greater than                                                                  |
| :greaterThanOrEquals | >=(x) | greater than or equals                                                           |
| :in                  | in(x) | specify multiple values to be compared                                           |
| :not                 |       | logical negation                                                                 |
| :and                 |       | logical AND (conjuction)                                                         |
| :or                  |       | logical OR (disjunction)                                                         |
| :like                |       | search for a pattern, ? matches one character, * matches zero or more characters |

# To pass instead of a value: 

|:isNull    | has an empty value    |
|:isNotNull | has a non-empty value | 


# Keywords

- `username`: String username for a gbif.org account
- `type`" `:and` or `:or` query.

Allowed query keywords are: 
`$(keys(occurrence_request_parameters()))`
"""
function occurrence_request(species::Species; kw...)
    query = _bestquery(species)
    isnothing(query) && error("Species has no keys to request occurrences for")
    occurrence_request(; query..., kw...)
end
function occurrence_request(; 
    username, notificationAddresses=nothing, format="SIMPLE_CSV", geoDistance=nothing, type="and", kw...
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
    predicates = [_predicate(params, k, v) for (k, v) in query]
    if !isnothing(geoDistance)
        keys(geoDistance) == (latitude, longitude, distance) || error()
        push!(predicates, (; type=:geoDistance, distance...))
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
    x = Base.getpass("Enter your GBIF password")
    passwd = read(x, String)
    auth = Base64.base64encode(username * ":" * passwd)
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
    key = JSON3.read(response.body)
    return key 
end

"""
    occurrence_download([key::String]; [filename]) 

Download the data for an occurrence key returned by `occurrence_request`,
or without arguments download the last result of `occurrence_request`.

Note that this depends on gbif.org preparing the download - prior to this
`occurrence_download` will give a 404 error.

The `filename` keyword can be used to name the resulting file.
"""
function occurrence_download(key::String=LAST_DOWNLOAD[]; filename = key * ".zip") 
    url = _joinurl(OCCURRENCE_DOWNLOAD_URL, "request", key)
    println("Downloading $key to $filename")
    return HTTP.download(url, filename)
end

function _predicate(params, key, val) 
    if val in (:isNull, :isNotNull)
        (type=val, key=params[k])
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
_valtype(v::Base.Fix2{typeof(<)}) = "lessThan"
_valtype(v::Base.Fix2{typeof(>=)}) = "greaterThanOrEquals"
_valtype(v::Base.Fix2{typeof(<=)}) = "lessThanOrEquals"

