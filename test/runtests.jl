using GBIF2
using Aqua
using HTTP
using JSON3
using DataFrames
using Test
using CSV

@testset "Aqua.jl" begin
    # Aqua.test_ambiguities([GBIF2, Base, Core])
    Aqua.test_unbound_args(GBIF2)
    Aqua.test_stale_deps(GBIF2)
    Aqua.test_undefined_exports(GBIF2)
    Aqua.test_project_extras(GBIF2)
    Aqua.test_deps_compat(GBIF2)
end

sp = species_match("Lalage newtoni"; class="Aves", verbose=true)

@testset "species_match" begin
    @test sp isa GBIF2.Species
    @test sp.species == "Coracina newtoni"
    @test sp.synonym == true
    @test_throws ArgumentError species_match("Lalage newtoni"; continent="Africa")
end
@testset "species" begin
    sp1 = species(sp)
    @test sp1 isa GBIF2.Species
    @test sp1.species == "Coracina newtoni"
    @test sp1.synonym isa Union{Bool,Missing}
    @test sp1.vernacularName == "Reunion Cuckooshrike"
    class = species(sp.classKey)
    @test ismissing(class.species)
    @test class.class == "Aves"
    @test class.vernacularName == "bird"
    @test_throws MethodError species("Lalage newtoni")
end
@testset "species_list" begin
    results = species_list("Lalage newtoni")
    sp1 = results[1]
    @test sp1 isa GBIF2.Species
    @test sp1.genus == "Coracina"
    @test_throws ArgumentError species_search("Lalage newtoni"; continent="Africa")
end
@testset "species_search" begin
    table = species_search("Lalage newtoni"; limit=10)
    @test GBIF2.query(table)[:q] == "Lalage newtoni" 
    @test GBIF2.limit(table) == 10
    @test GBIF2.offset(table) == 0
    @test GBIF2.count(table) isa Int64
    @test GBIF2.count(table) > 10
    @test GBIF2.endOfRecords(table) == false

    @test table isa GBIF2.Table
    sh = sprint(show, MIME"text/plain"(), table)
    @test occursin("──┬──", sh)
    sp1 = table[1]
    @test sp1 isa GBIF2.Species
    @test sp1.genus == "Lalage"
    @test_throws ArgumentError species_search("Lalage newtoni"; continent="Africa")

    longtable = species_search("Acridotheres tristis"; limit=700)
    GBIF2.count(longtable)

    @testset "species tables write to CSV" begin
        CSV.write("species_test.csv", longtable)
        df = CSV.read("species_test.csv", DataFrame)
        foreach(enumerate(Tables.columns(df)), Tables.columns(DataFrame(longtable))) do (i, written), orig
            if !(i == 34) # Vector{String} => String
                @test all(map(written, orig) do w, o
                    ismissing(w) && ismissing(o) || ismissing(w) && isempty(o) || w == o
                end)
            end
        end
    end
end
@testset "occurrence" begin
    ocs = occurrence_search(sp)
    oc1 = occurrence(ocs[1])
    @test oc1 isa GBIF2.Occurrence
    @test_throws ArgumentError species_search("Lalage newtoni"; not_a_keyword=2)
    @test_throws HTTP.ExceptionRequest.StatusError occurrence(1)
    @test_throws HTTP.ExceptionRequest.StatusError occurrence(1, 2)
    oc_verbatim = occurrence(ocs[1]; returntype=:verbatim)
    @test oc_verbatim isa JSON3.Object
    oc_verbatim = occurrence(ocs[1]; returntype=:fragment)
    @test oc_verbatim isa JSON3.Object
end
@testset "occurrence_search" begin
    results = occurrence_search(sp)
    oc1 = results[1]
    @test oc1 isa GBIF2.Occurrence
    @test all(results.species .== "Coracina newtoni")
    @testset "occurrence tables write to CSV" begin
        CSV.write("occurence_test.csv", results)
        df = CSV.read("occurence_test.csv", DataFrame)
        foreach(enumerate(Tables.columns(df)), Tables.columns(DataFrame(results))) do (i, written), orig
            if i == 73
                @test all(parse.(Int64, orig) .== written)
                nothing
            elseif i in [1, 19, 46, 49, 50, 51, 52, 61, 62]
                # skip
                # 20 => DateTime, 45-6: Vector{String} => String
            else
                match = map(written, orig) do w, o
                    ismissing(w) && ismissing(o) || w == o
                end |> all || @show i written orig
                
            end
        end
    end
    @test_throws ArgumentError species_search("Lalage newtoni"; not_a_keyword=2)
    results = occurrence_search(returntype=:occurrenceId, q = "https://www.inaturalist.org/observations")
    @test results isa AbstractVector{<:String} # TODO maybe it should be specialised to Int
    results = occurrence_search("")
end
@testset "occurrence_count" begin
    c1 = occurrence_count(sp)
    @test c1 isa Int64
    c2 = occurrence_count(sp; country=:RE, basisOfRecord=:PRESERVED_SPECIMEN)
    @test c2 isa Int64
    @test c1 > c2
end
@testset "occurrence_count_schema" begin
    # Just run it
    GBIF2.occurrence_count_schema() 
end
@testset "occurrence_inventory" begin
    country_counts = occurrence_inventory(:countries)
    @test country_counts isa JSON3.Object 
    @test country_counts.SPAIN isa Int64
end
@testset "occurrence_request" begin
    # Need to look at the best way to test this given
    # the password requiements and download delay

    # This just throws an error due to wrong username/password
    @test_throws HTTP.ExceptionRequest.StatusError occurrence_request(sp; username="test", password="test")
    @test_throws HTTP.ExceptionRequest.StatusError occurrence_request(sp; username="test", password="test", notificationAddresses="test@email.com")
    @test_throws HTTP.ExceptionRequest.StatusError occurrence_request(sp; username="test", password="test", notificationAddresses="test@email.com")
    @test_throws HTTP.ExceptionRequest.StatusError occurrence_request(sp; username="test", password="test", notificationAddresses=["test@email.com"])
    @test_throws ArgumentError occurrence_request(sp; username="test", password="test", geoDistance=(wrong=1, keys=2))
    @test_throws HTTP.ExceptionRequest.StatusError occurrence_request(sp; username="test", password="test", geoDistance=(latitude=1, longitude=2, distance=3))
end
@testset "occurrence_download" begin
    test_key = "12345"
    @test_throws HTTP.ExceptionRequest.StatusError occurrence_download(test_key)
end
@testset "DataFrames" begin
    @testset "DataFrames from Occurrence" begin
        ocs = occurrence_search(; taxonKey=sp.speciesKey, limit=1000)
        df = DataFrame(ocs)
        @test nrow(df) == 1000
        @test names(df) == string.(collect(Tables.propertynames(ocs)))
        @test all(df.decimalLongitude .=== ocs.decimalLongitude)
        @testset "from a subset vector" begin
            df = DataFrame(ocs[1:500])
            @test nrow(df) == 500
            @test names(df) == string.(collect(Tables.propertynames(ocs)))
        end
    end
    @testset "DataFrames from Species" begin
        sps = species_list("Lalage newtoni"; limit=5)

        df = DataFrame(sps)
        @test nrow(df) == 5
        @test names(df) == string.(collect(propertynames(sps))) == string.(collect(propertynames(first((sps)))))
        @test all(sps.kingdom .=== df.kingdom)
        @testset "from a subset vector" begin
            df = DataFrame(sps[1:3])
            @test nrow(df) == 3
            @test names(df) == string.(collect(Tables.propertynames(sps)))
        end
    end
end
