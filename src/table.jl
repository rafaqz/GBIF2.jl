
"""
    Table <: AbstractVector

A generic `Vector` and Tables.jl compatible table to hold both
`Occurrence` and `Species` data.

Use as any julia `AbstractArray` to access species or occurrence records,
or use with the Tables.jl interface to convert to a DataFrame or e.g. CSV.
"""
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
    res = json.results
    count = :count in keys(json) ? json.count : length(res)
    Table{T,typeof(res)}(
        query, json.offset, json.limit, json.endOfRecords, count, res,
    )
end
# Allow manually constructing `Table` to make a table from an Array
function Table(values::AbstractArray{T}) where T<:Union{Species,Occurrence}
    objects = object.(values)
    Table{T,typeof(objects)}(
         Dict{Symbol,Any}(), 0, 0, true, length(objects), objects,
    )
end

query(t::Table) = getfield(t, :query)
offset(t::Table) = getfield(t, :offset)
limit(t::Table) = getfield(t, :limit)
endOfRecords(t::Table) = getfield(t, :endOfRecords)
count(t::Table) = getfield(t, :count)
results(t::Table) = getfield(t, :results)

Base.getindex(table::Table{T}, i::Int) where T = T(getindex(results(table), i))
Base.size(table::Table, args...) = size(results(table), args...)
function Base.show(io::IO, mime::MIME"text/plain", table::Table)
    print(io, length(table), "-element ", typeof(table))
    PrettyTables.pretty_table(io, table)
end
function Base.vcat(tables::Table{T}...) where T
    res = vcat(map(table -> results(table), tables)...)
    Table{T,typeof(res)}(
        query(first(tables)),
        offset(first(tables)),
        limit(first(tables)),
        endOfRecords(last(tables)),
        length(res),
        res,
    )
end
function Base.getproperty(table::Table{Occurrence}, k::Symbol)
    k in keys(occurrence_properties()) || error("Occurrence has no field $k")
    return getproperty.(table, k)
end
function Base.getproperty(table::Table{Species}, k::Symbol)
    k in keys(species_properties()) || error("Species has no field $k")
    return getproperty.(table, k)
end
Base.propertynames(table::Table{Occurrence}) = keys(occurrence_properties())
Base.propertynames(table::Table{Species}) = keys(species_properties())

Tables.istable(::Table) = true
Tables.rowaccess(::Table) = true
Tables.schema(::Table{T}) where T = _schema(T)
