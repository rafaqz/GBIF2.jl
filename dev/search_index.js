var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = GBIF2","category":"page"},{"location":"#GBIF2","page":"Home","title":"GBIF2","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for GBIF2.","category":"page"},{"location":"","page":"Home","title":"Home","text":"GBIF2","category":"page"},{"location":"#GBIF2.GBIF2","page":"Home","title":"GBIF2.GBIF2","text":"GBIF2\n\n(Image: Stable) (Image: Dev) (Image: Build Status) (Image: Coverage)\n\nThe goals of GBIF2 is to follow the GBIF api as completely and correctly as possible.\n\nIts main design features are:\n\nSingle results are Occurrence or Species objects with all GBIF fields available using object.fieldname,   returning missing if not returned by a specific query.\nMultiple results are returned as a Tables.jl compatible Table of Occurrence or Species rows.    This Table can be converted to a DataFrame or writted directly to disk using CSV.jl and similar packages.\nAll GBIF enum keys are checked for correctness before querying so that only correct queries can be sent.    Clear messages point to errors in queries.\nA limit above 300 items at a time is allowed, unlike in the original API, by making   multiple reuests and joining the results.\nFor even larger queries, download requests are handled with gbif.org account authentication.\n\nA quick example\n\njulia> using GBIF2, DataFrames\n\n# Basic species match with `species_match`:\njulia> sp = species_match(\"Lalage newtoni\");\n\njulia> sp.species\n\"Coracina newtoni\"\n\njulia> sp.synonym\ntrue\n\njulia> sp.vernacularName\nmissing\n\n# Get a more detailed object with `species`:\njulia> sp_detailed = species(sp);\n\njulia> sp_detailed.vernacularName\n\"Reunion Cuckooshrike\"\n\n# Get the first 2000 occurrences for the species from 2000 to 2020, on reunion:\njulia> oc = occurrence_search(sp;\n           limit=2000, country=:RE, hasCoordinate=true, year=(2000,2020)\n       ) |> DataFrame\n2000×83 DataFrame\n  Row │ decimalLongitude  decimalLatitude  year    month   day\n      │ Float64?          Float64?         Int64?  Int64?  Int64?\n──────┼────────────────────────────────────────────────────────────\n    1 │          55.5085         -21.0192    2020       1      14\n    2 │          55.4133         -20.928     2020       1      23\n    3 │          55.4133         -20.928     2020       1      16\n    4 │          55.5085         -21.0192    2020       1      14\n    5 │          55.4123         -21.0184    2020       1      13\n    6 │          55.4133         -20.928     2020       1      28\n    7 │          55.4133         -20.928     2020       1      16\n  ⋮   │        ⋮                 ⋮           ⋮       ⋮       ⋮\n 1994 │          55.4133         -20.928     2017      10      29\n 1995 │          55.4123         -21.0184    2017      10      25\n 1996 │          55.4123         -21.0184    2017      10      25\n 1997 │          55.4123         -21.0184    2017      10      17\n 1998 │          55.4123         -21.0184    2017      10      25\n 1999 │          55.4123         -21.0184    2017      10      25\n 2000 │          55.4123         -21.0184    2017      10      25\n\n\n\n\n\n","category":"module"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"There are a number of ways to query the GBIF database for species,  returning different numbers of results and amounts of data.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Species objects and queries correspond closely to the GBIF species api.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Species\nspecies\nspecies_list\nspecies_match\nspecies_search","category":"page"},{"location":"#GBIF2.Species","page":"Home","title":"GBIF2.Species","text":"Species\n\nWrapper object for information returned by species, species_list , species_match  or species_search queries. These often are species, but a more correctly taxa, as it may be e.g. \"Aves\" for all birds. We use Species for naming consistency with the GBIF API.\n\nSpecies also serve as rows in Table, and are converted to rows in a DataFrame or CSV automatically by the Tables.jl interface.\n\nSpecies properties are accessed with ., e.g. sp.kingdom. Note that these queries do not all return all properties, and not all records contain all properties in any case. Missing properties simply return missing.\n\nThe possible properties of a Species object are: (kingdom = Union{Missing, String}, phylum = Union{Missing, String}, class = Union{Missing, String}, order = Union{Missing, String}, family = Union{Missing, String}, genus = Union{Missing, String}, species = Union{Missing, String}, key = Union{Missing, Int64}, nubKey = Union{Missing, Int64}, nameKey = Union{Missing, Int64}, taxonID = Union{Missing, String}, sourceTaxonKey = Union{Missing, Int64}, kingdomKey = Union{Missing, Int64}, phylumKey = Union{Missing, Int64}, classKey = Union{Missing, Int64}, orderKey = Union{Missing, Int64}, familyKey = Union{Missing, Int64}, genusKey = Union{Missing, Int64}, speciesKey = Union{Missing, Int64}, datasetKey = Union{Missing, String}, constituentKey = Union{Missing, String}, scientificName = Union{Missing, String}, canonicalName = Union{Missing, String}, vernacularName = Union{Missing, String}, parentKey = Union{Missing, Int64}, parent = Union{Missing, String}, basionymKey = Union{Missing, Int64}, basionym = Union{Missing, String}, authorship = Union{Missing, String}, nameType = Union{Missing, String}, rank = Union{Missing, String}, origin = Union{Missing, String}, taxonomicStatus = Union{Missing, String}, nomenclaturalStatus = Union{Missing, Vector{String}}, remarks = Union{Missing, String}, publishedIn = Union{Missing, String}, numDescendants = Union{Missing, Int64}, lastCrawled = Union{Missing, String}, lastInterpreted = Union{Missing, String}, issues = Union{Missing, Vector{String}}, synonym = Union{Missing, Bool})\n\n\n\n\n\n","category":"type"},{"location":"#GBIF2.species","page":"Home","title":"GBIF2.species","text":"species(key; kw...)\nspecies(key, resulttype; kw...)\n\nQuery the GBIF species api, returning a single Species.\n\nkey: a species key, or Species object from another search that a key can be   obtained from.\nresulttype: set this so that instead of a Species, species will return an   object in (:verbatim, :name, :parents, :children, :related, :synonyms, :combinations, :descriptions, :distributions, :media, :references, :speciesProfiles, :vernacularNames, :typeSpecimens). The return value will be a raw JSON3.Object,   but itspropertynames` can be checked and used to access data.\n\nExample\n\nHere we find a species with species_search, and then obtain the complete record with species.\n\njulia> using GBIF2\njulia> tbl = species_search(\"Falco punctatus\")\n20-element GBIF2.Table{GBIF2.Species, JSON3.Array{JSON3.Object, Vector{UInt8}, SubArray{\nUInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}}}\n┌──────────┬──────────┬───────────────┬───────────────┬────────────┬─────────┬──────────\n│  kingdom │   phylum │         class │         order │     family │   genus │         ⋯\n│  String? │  String? │       String? │       String? │    String? │ String? │         ⋯\n├──────────┼──────────┼───────────────┼───────────────┼────────────┼─────────┼──────────\n│ Animalia │  missing │          Aves │ Falconiformes │ Falconidae │ missing │ Falco p ⋯\n│ Animalia │  missing │          Aves │       missing │ Falconidae │   Falco │ Falco p ⋯\n│  missing │  missing │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯\n│  missing │ Chordata │       missing │       missing │ Falconidae │   Falco │ Falco p ⋯\n│ Animalia │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯\n│ Animalia │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯\n│  Metazoa │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯\n│ Animalia │  missing │       missing │ Falconiformes │ Falconidae │ missing │ Falco p ⋯\n│  Metazoa │ Chordata │          Aves │ Falconiformes │ Falconidae │   Falco │ Falco p ⋯\n│    ⋮     │    ⋮     │       ⋮       │       ⋮       │     ⋮      │    ⋮    │         ⋱\n└──────────┴──────────┴───────────────┴───────────────┴────────────┴─────────┴──────────\n                                                          35 columns and 11 rows omitted\n\njulia> species(tbl[6])\nGBIF2.Species({\n                   \"key\": 102091853,\n                \"nubKey\": 2481005,\n               \"nameKey\": 4400647,\n               \"taxonID\": \"175650\",\n               \"kingdom\": \"Animalia\",\n                \"phylum\": \"Chordata\",\n                 \"order\": \"Falconiformes\",\n                \"family\": \"Falconidae\",\n                 \"genus\": \"Falco\",\n               \"species\": \"Falco punctatus\",\n            \"kingdomKey\": 101683523,\n             \"phylumKey\": 102017110,\n              \"classKey\": 102085317,\n              \"orderKey\": 102091762,\n             \"familyKey\": 102091763,\n              \"genusKey\": 102091765,\n            \"speciesKey\": 102091853,\n            \"datasetKey\": \"9ca92552-f23a-41a8-a140-01abaa31c931\",\n             \"parentKey\": 102091765,\n                \"parent\": \"Falco\",\n        \"scientificName\": \"Falco punctatus Temminck, 1821\",\n         \"canonicalName\": \"Falco punctatus\",\n        \"vernacularName\": \"Mauritius Kestrel\",\n            \"authorship\": \"Temminck, 1821\",\n              \"nameType\": \"SCIENTIFIC\",\n                  \"rank\": \"SPECIES\",\n                \"origin\": \"SOURCE\",\n       \"taxonomicStatus\": \"ACCEPTED\",\n   \"nomenclaturalStatus\": [],\n        \"numDescendants\": 0,\n           \"lastCrawled\": \"2022-10-10T18:15:33.989+00:00\",\n       \"lastInterpreted\": \"2022-10-10T19:16:16.841+00:00\",\n                \"issues\": [\n                            \"SCIENTIFIC_NAME_ASSEMBLED\"\n                          ],\n               \"synonym\": false,\n                 \"class\": \"Aves\"\n})\n\nKeyword arguments\n\nlanguage: can be specified for a single argument or with second argument in   (:parents, :children, :related, :synonyms). \ndatasetKey: can be specified, with a second argument :related.\n\n\n\n\n\n","category":"function"},{"location":"#GBIF2.species_list","page":"Home","title":"GBIF2.species_list","text":"species_list(; kw...)\nspecies_list(key; kw...)\nspecies_list(key, resulttype; kw...)\n\nQuery the GBIF species_list api, returning a table of Species that exactly match your query.\n\nExample\n\nusing GBIF2\nspecies_list(; name=\"Lalage newtoni\")\n\n# output\n8-element GBIF2.Table{GBIF2.Species, JSON3.Array{JSON3.Object, Vector{UInt8}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}}}\n┌──────────┬──────────┬───────────────┬───────────────┬───────────────┬──────────┬──────────────────┬───────────┬─────────┬──────────┬──────────────┬────────────────┬───────\n│  kingdom │   phylum │         class │         order │        family │    genus │          species │       key │  nubKey │  nameKey │      taxonID │ sourceTaxonKey │ king ⋯\n│  String? │  String? │       String? │       String? │       String? │  String? │          String? │    Int64? │  Int64? │   Int64? │      String? │         Int64? │      ⋯\n├──────────┼──────────┼───────────────┼───────────────┼───────────────┼──────────┼──────────────────┼───────────┼─────────┼──────────┼──────────────┼────────────────┼───────\n│ Animalia │ Chordata │          Aves │ Passeriformes │ Campephagidae │ Coracina │ Coracina newtoni │   8385394 │ missing │ 18882488 │ gbif:8385394 │      176651982 │      ⋯\n│ Animalia │  missing │          Aves │       missing │ Campephagidae │   Lalage │   Lalage newtoni │ 100144670 │ 8385394 │  5976204 │        06014 │        missing │  128 ⋯\n│ Animalia │  missing │          Aves │ Passeriformes │ Campephagidae │  missing │   Lalage newtoni │ 133165079 │ 8385394 │  5976204 │        18380 │        missing │  135 ⋯\n│ Animalia │ Chordata │          Aves │ Passeriformes │ Campephagidae │   Lalage │   Lalage newtoni │ 161400685 │ 8385394 │ 18882488 │       895898 │        missing │  134 ⋯\n│  missing │  missing │       missing │       missing │       missing │ Bossiaea │   Lalage newtoni │ 165585935 │ missing │ 18882488 │      6924877 │        missing │    m ⋯\n│ Animalia │  missing │          Aves │ Passeriformes │ Campephagidae │   Lalage │   Lalage newtoni │ 165923305 │ 8385394 │ 18882488 │        19393 │        missing │  100 ⋯\n│ Animalia │ Chordata │          Aves │ Passeriformes │ Campephagidae │   Lalage │   Lalage newtoni │ 168010293 │ 8385394 │  5976204 │       181376 │        missing │  167 ⋯\n│ Animalia │ Chordata │ Passeriformes │          Aves │ Campephagidae │   Lalage │   Lalage newtoni │ 176651982 │ 8385394 │ 18882488 │     22706569 │        missing │  202 ⋯\n└──────────┴──────────┴───────────────┴───────────────┴───────────────┴──────────┴──────────────────┴───────────┴─────────┴──────────┴──────────────┴────────────────┴───────\n\nKeyword arguments\n\nWe use keywords exactly as in the GBIF api.\n\nYou can find keyword enum values with the [GBIF2.enum](@ref) function.\n\nlanguage: Language for vernacular names, given as an ISO 639-1 two-letter code from our\ndatasetKey: Filters by the checklist dataset key (a uuid)\nsourceId: Filters by the source identifier\nname: Name of the species\noffset: Offset to start results from\nlimit: The maximum number of results to return. This can't be greater than 300, any value greater is set to 300.\n\n\n\n\n\n","category":"function"},{"location":"#GBIF2.species_match","page":"Home","title":"GBIF2.species_match","text":"species_match(; kw...)\n\nQuery the GBIF species/match api, returning the single closest Species using fuzzy search.\n\nThe results are not particularly detailed, this can be improved by calling  species(res) on the result of species_match to query for the full dataset.\n\nExample\n\nusing GBIF2\nsp = species_match(\"Lalage newtoni\")\n\n# output\nGBIF2.Species({\n           \"usageKey\": 8385394,\n   \"acceptedUsageKey\": 2486791,\n     \"scientificName\": \"Lalage newtoni (Pollen, 1866)\",\n      \"canonicalName\": \"Lalage newtoni\",\n               \"rank\": \"SPECIES\",\n             \"status\": \"SYNONYM\",\n         \"confidence\": 98,\n          \"matchType\": \"EXACT\",\n            \"kingdom\": \"Animalia\",\n             \"phylum\": \"Chordata\",\n              \"order\": \"Passeriformes\",\n             \"family\": \"Campephagidae\",\n              \"genus\": \"Coracina\",\n            \"species\": \"Coracina newtoni\",\n         \"kingdomKey\": 1,\n          \"phylumKey\": 44,\n           \"classKey\": 212,\n           \"orderKey\": 729,\n          \"familyKey\": 9284,\n           \"genusKey\": 2482359,\n         \"speciesKey\": 2486791,\n            \"synonym\": true,\n              \"class\": \"Aves\"\n})\n\nKeywords\n\nWe use keywords exactly as in the GBIF api.\n\nYou can find keyword enum values with the [GBIF2.enum](@ref) function.\n\nrank: Filters by taxonomic rank as given in our Rank enum\nname: Name of the species\nstrict: If true it (fuzzy) matches only the given name, but never a taxon in the upper classification\nverbose: If true it shows alternative matches which were considered but then rejected\nkingdom: Optional kingdom classification accepting a canonical name.\nphylum: Optional phylum classification accepting a canonical name.\nclass: Optional class classification accepting a canonical name.\norder: Optional order classification accepting a canonical name.\nfamily: Optional family classification accepting a canonical name.\ngenus: Optional genus classification accepting a canonical name.\n\n\n\n\n\n","category":"function"},{"location":"#GBIF2.species_search","page":"Home","title":"GBIF2.species_search","text":"species_search([q]; kw...)\n\nQuery the GBIF species/search api, returning many results in a GBIF2.Table.\n\nExample\n\nusing GBIF2\nsp = species_search(\"Psittacula eques\")\n\n# output\n20-element GBIF2.Table{GBIF2.Species, JSON3.Array{JSON3.Object, Vector{UInt8}, SubArray{UInt64, 1,\nVector{UInt64}, Tuple{UnitRange{Int64}}, true}}}\n┌──────────┬──────────┬────────────────┬────────────────┬───────────────┬──────────────┬───────────\n│  kingdom │   phylum │          class │          order │        family │        genus │          ⋯\n│  String? │  String? │        String? │        String? │       String? │      String? │          ⋯\n├──────────┼──────────┼────────────────┼────────────────┼───────────────┼──────────────┼───────────\n│ Animalia │ Chordata │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯\n│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │      missing │          ⋯\n│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │   Psitta ⋯\n│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │      missing │   Psitta ⋯\n│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │      missing │          ⋯\n│ Animalia │  missing │        missing │ Psittaciformes │ Psittaculidae │      missing │   Psitta ⋯\n│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │   Psitta ⋯\n│  missing │  missing │        missing │        missing │       missing │   Psittacula │   Psitta ⋯\n│ Animalia │ Chordata │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯\n│ Animalia │  missing │           Aves │        missing │   Psittacidae │   Psittacula │   Psitta ⋯\n│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │    Psitt ⋯\n│ Animalia │ Chordata │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯\n│ ANIMALIA │ CHORDATA │ PSITTACIFORMES │           AVES │   PSITTACIDAE │ Alexandrinus │ Alexandr ⋯\n│  Metazoa │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │    Psitt ⋯\n│ Animalia │ Chordata │           Aves │ Psittaciformes │   Psittacidae │   Psittacula │   Psitta ⋯\n│ Animalia │  missing │           Aves │ Psittaciformes │ Psittaculidae │   Psittacula │   Psitta ⋯\n│    ⋮     │    ⋮     │       ⋮        │       ⋮        │       ⋮       │      ⋮       │          ⋱\n└──────────┴──────────┴────────────────┴────────────────┴───────────────┴──────────────┴───────────\n                                                                      35 columns and 4 rows omitted\n\nKeyword arguments\n\nWe use keywords exactly as in the GBIF api.\n\nclass: Optional class classification accepting a canonical name.\ndatasetKey: Filters by the checklist dataset key (a uuid)\nfacet: A list of facet names used to retrieve the 100 most frequent values for a field.\n\nAllowed facets are :datasetKey, :higherTaxonKey, :rank, :status, :nomenclaturalStatus, isExtinct, :habitat, :threat and :nameType.\n\nfacetMincount: Used in combination with the facet parameter. Set facetMincount=N to exclude facets\n\nwith a count less than N, e.g. facet=type, limit=>0, facetMincount=>10000 only shows the type value OCCURRENCE because :CHECKLIST and :METADATA have counts less than 10000.\n\nfacetMultiselect: Used in combination with the facet parameter. Set facetMultiselect=true to still\n\nreturn counts for values that are not currently filtered, e.g. facet=type, limit=>0, type=>CHECKLIST, facetMultiselect=>true still shows type values OCCURRENCE and METADATA even though type is being filtered by type=:CHECKLIST\n\nfamily: Optional family classification accepting a canonical name.\ngenus: Optional genus classification accepting a canonical name.\nhabitat: Filters by the habitat. Currently only 3 major biomes are accepted in our Habitat enum\nhighertaxonKey: Filters by any of the higher Linnean rank keys. Note this is within the respective\",\n\nchecklist and not searching nub keys across all checklists.\n\nhl: Set hl=true to highlight terms matching the query when in fulltext search fields.\",\n\nThe highlight will be an emphasis tag of class 'gbifH1' e.g. q=\"plant\", hl=>true.\", Fulltext search fields include title, keyword, country, publishing country, publishing organization title,\", hosting organization title, and description. One additional full text field is searched which includes\", information from metadata documents, but the text of this field is not returned in the response.\n\nisExtinct: Filters by extinction status (a boolean, e.g. isExtinct=>true)\nissue: A specific indexing issue as defined in our NameUsageIssue enum\nkingdom: Optional kingdom classification accepting a canonical name.\nlanguage: Language for vernacular names, given as an ISO 639-1 two-letter code from our\nnameType: Filters by the name type as given in our NameType enum\nnomenclaturalStatus: Not yet implemented, but will eventually allow for filtering by a nomenclatural status enum\norder: Optional order classification accepting a canonical name.\nphylum: Optional phylum classification accepting a canonical name.\nq: Simple full text search parameter. The value for this parameter can be a simple word or a phrase.\n\nWildcards are not supported\n\nrank: Filters by taxonomic rank as given in our Rank enum\nsourceId: Filters by the source identifier\nstatus: Filters by the taxonomic status as given in our TaxonomicStatus enum\nstrict: If true it (fuzzy) matches only the given name, but never a taxon in the upper classification\nthreat: Filters by the taxonomic threat status as given in our ThreatStatus enum\nverbose: If true it shows alternative matches which were considered but then rejected\noffset: Offset to start results from\nlimit: The maximum number of results to return. This can't be greater than 300, any value greater is set to 300.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"Occurrence objects and queries correspond closely to the GBIF occurrence api.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Occurrence\noccurrence\noccurrence_search\noccurrence_request\noccurrence_download\noccurrence_count\noccurrence_inventory","category":"page"}]
}
