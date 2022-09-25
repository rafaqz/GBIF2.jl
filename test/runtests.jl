using GBIF2
using Test
using HTTP
using DataFrames


@testset "GBIF2.jl" begin
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
        results = species_search("Lalage newtoni")
        sp1 = results[1]
        @test sp1 isa GBIF2.Species
        @test sp1.genus == "Lalage"
        @test_throws ArgumentError species_search("Lalage newtoni"; continent="Africa")
    end
    @testset "occurance_search" begin
        results = occurrence_search(sp; continent=:AFRICA)
        oc1 = results[1]
        @test oc1 isa GBIF2.Occurrence
        @test oc1.genus == "Coracina"
        @test_throws ArgumentError species_search("Lalage newtoni"; not_a_keyword=2)
    end
    @testset "occurance_count" begin
        c1 = occurrence_count(sp)
        @test c1 isa Int64
        c2 = occurrence_count(sp; country=:RE, basisOfRecord=:PRESERVED_SPECIMEN)
        @test c2 isa Int64
        @test c1 > c2
    end
    @testset "DataFrames" begin
        ocs = occurrence_search(; taxonKey=sp.speciesKey, limit=1000)
        df = DataFrame(ocs)
        @test nrow(df) == 1000
    end
end
