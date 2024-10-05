module GBIF2

# Use readme as module docs
@doc let
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end GBIF2

using Dates

import Base64
import JSON3
import GeoInterface as GI
import GeoFormatTypes as GFT
import HTTP
import PrettyTables
import Tables
import WellKnownGeometry

export species, species_list, species_match, species_search
export occurrence, occurrence_search, occurrence_count, occurrence_inventory, occurrence_request, occurrence_download

const GBIF_URL = "http://api.gbif.org/v1/"

include("enums.jl")
include("parameters.jl")
include("utils.jl")
include("species.jl")
include("occurrence.jl")
include("table.jl")

end # module
