using Taxonomy
using Test

db = Taxonomy.DB("db/nodes.dmp","db/names.dmp")

@testset "taxon.jl" begin
    @test Taxon <: AbstractTaxon
    @test UnclassifiedTaxon <: AbstractTaxon

    human = Taxon(9606,db)
    @test typeof(human) == Taxon
    @test human.name == "Homo sapiens"
    @test human.taxid == 9606
    @test human.rank == :species
    @test sprint(io -> show(io, human)) == "9606 [species] Homo sapiens"

    @test get(9606, db, nothing) == human

    @test taxid(human) == human.taxid
    @test rank(human) == human.rank
    @test parent(human) == Taxon(9605,db)
    @test children(human) == [Taxon(741158,db), Taxon(63221,db)]

    unclassified_human_subspecies = UnclassifiedTaxon(:subspecies, human)
    @test typeof(unclassified_human_subspecies) == UnclassifiedTaxon
    @test unclassified_human_subspecies.name == "unclassified Homo sapiens subspecies"
    @test unclassified_human_subspecies.rank == :subspecies
    @test unclassified_human_subspecies.source == human
    @test sprint(io -> show(io, unclassified_human_subspecies)) == "Unclassified [subspecies] unclassified Homo sapiens subspecies"

    @test rank(unclassified_human_subspecies) == unclassified_human_subspecies.rank

    @test_throws KeyError Taxon(99999999, db)
    @test get(9999999, db, nothing) === nothing
end
