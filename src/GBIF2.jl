module GBIF2

using Base64, Dates, HTTP, JSON3, Tables

export species, species_list, species_match, species_search
export occurrence, occurrence_search, occurrence_count, occurrence_request, occurrence_download

const GBIF_URL = "http://api.gbif.org/v1/"

include("enums.jl")
include("parameters.jl")
include("utils.jl")
include("results.jl")
include("species.jl")
include("occurrence.jl")

end # module
