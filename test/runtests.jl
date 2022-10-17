using GBIF2
using Aqua
using HTTP
using JSON3
using DataFrames
using Test

# Aqua.test_ambiguities([GBIF2, Base, Core])
Aqua.test_unbound_args(GBIF2)
Aqua.test_stale_deps(GBIF2)
Aqua.test_undefined_exports(GBIF2)
Aqua.test_project_extras(GBIF2)
Aqua.test_deps_compat(GBIF2)
Aqua.test_project_toml_formatting(GBIF2)

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
    @test sp1.synonym == false
    @test sp1.vernacularName == "Reunion Cuckooshrike"
    class = species(sp.classKey)
    @test ismissing(class.species)
    @test class.class == "Aves"
    @test class.vernacularName == "Birds"
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
    @test GBIF2.count(table) isa Int
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
    @test oc1.genus == "Hippophae"
    @test_throws ArgumentError species_search("Lalage newtoni"; not_a_keyword=2)
    results = occurrence_search(sp; returntype=:catalogNumber)
    @test results isa AbstractVector{<:String} # TODO maybe it shouls be specialised to Int
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
    @test country_counts.SPAIN isa Int
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
