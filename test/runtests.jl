using GBIF2
using Test
using HTTP


@testset "GBIF2.jl" begin
    sp = species_match("Lalage newtoni"; class="Aves", verbose=true)
    @testset "species_match" begin
        @test sp isa GBIF2.Species
        @test sp.species == "Coracina newtoni"
        @test sp.synonym == true
        @test_throws ArgumentError species_match("Lalage newtoni"; continent="Africa")
    end
    @testset "species" begin
        sp1 = species(sp.speciesKey, :references)
        sp1.results[1]
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
        @test sp1.genus == "Lalage"
        @test_throws ArgumentError species_search("Lalage newtoni"; continent="Africa")
    end
    @testset "species_search" begin
        results = species_search("Lalage newtoni")
        sp1 = results[1]
        @test sp1 isa GBIF2.Species
        @test sp1.genus == "Lalage"
        @test_throws ArgumentError species_search("Lalage newtoni"; continent="Africa")
    end
end
