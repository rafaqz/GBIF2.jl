
struct Results{T,A} <: AbstractVector{T}
    query::Dict{Symbol,Any}
    offset::Int
    limit::Int
    endOfRecords::Bool
    count::Int
    results::A
end
Results{T}(query, raw::Union{AbstractString,AbstractVector{UInt8}}) where T = Results{T}(query, JSON3.read(raw))
function Results{T}(query, json::JSON3.Object) where T
    results = json.results
    count = :count in keys(json) ? json.count : length(results)
    Results{T,typeof(results)}(
        query, json.offset, json.limit, json.endOfRecords, count, results,
    )
end

Base.getindex(res::Results{T}, i::Int) where T = T(getindex(res.results, i))
Base.size(res::Results, args...) = size(res.results, args...)
function Base.show(io::IO, mime::MIME"text/plain", res::Results)
    print(io, length(res), "-element ", typeof(res)) 
end
function Base.vcat(resz::Results{T}...) where T
    results = vcat(map(res -> res.results, resz)...)
    Results{T,typeof(results)}(
        first(resz).query,
        first(resz).offset,
        first(resz).limit,
        last(resz).endOfRecords,
        length(results),
        results,
    )
end

Tables.istable(::Results) = true
Tables.rowaccess(::Results) = true
Tables.schema(::Results{T}) where T = Tables.schema(T)

function next(res::Results{T}; limit=res.limit) where T
    offset = res.offset + limit
    if T <: Occurrence
        occurrence(; pairs(res.query)..., offset, limit)
        occurrence(; pairs(res.query)..., offset, limit)
    elseif T <: Species
        species(; pairs(res.query)..., offset, limit)
        occurrence(; pairs(res.query)..., offset, limit)
    end
end
