
struct Table{T,A} <: AbstractVector{T}
    query::Dict{Symbol,Any}
    offset::Int
    limit::Int
    endOfRecords::Bool
    count::Int
    results::A
end
Table{T}(query, raw::Union{AbstractString,AbstractVector{UInt8}}) where T = Table{T}(query, JSON3.read(raw))
function Table{T}(query, json::JSON3.Object) where T
    results = json.results
    count = :count in keys(json) ? json.count : length(results)
    Table{T,typeof(results)}(
        query, json.offset, json.limit, json.endOfRecords, count, results,
    )
end
# Allow manually constructing `Table` to make a table from an Array
function Table(values::AbstractArray{T}) where T<:Union{Species,Occurrence}
    objects = object.(values)
    Table{T,typeof(objects)}(
         Dict{Symbol,Any}(), 0, 0, true, length(objects), objects,
    )
end

Base.getindex(res::Table{T}, i::Int) where T = T(getindex(res.results, i))
Base.size(res::Table, args...) = size(res.results, args...)
function Base.show(io::IO, mime::MIME"text/plain", res::Table)
    print(io, length(res), "-element ", typeof(res)) 
end
function Base.vcat(resz::Table{T}...) where T
    results = vcat(map(res -> res.results, resz)...)
    Table{T,typeof(results)}(
        first(resz).query,
        first(resz).offset,
        first(resz).limit,
        last(resz).endOfRecords,
        length(results),
        results,
    )
end

Tables.istable(::Table) = true
Tables.rowaccess(::Table) = true
Tables.schema(::Table{T}) where T = Tables.schema(T)

function next(res::Table{T}; limit=res.limit) where T
    offset = res.offset + limit
    if T <: Occurrence
        occurrence(; pairs(res.query)..., offset, limit)
        occurrence(; pairs(res.query)..., offset, limit)
    elseif T <: Species
        species(; pairs(res.query)..., offset, limit)
        occurrence(; pairs(res.query)..., offset, limit)
    end
end
