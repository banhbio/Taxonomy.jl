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
    denisova = Taxon(741158,db)
    @test children(denisova) == Taxon[]
    @test isempty(children(denisova))

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

@testset "lineage.jl" begin
    human = Taxon(9606,db)
    lineage = Lineage(human)
    @test lineage[1] == Taxon(1,db)
    @test size(lineage) == (32,)
    @test lineage[32] == human
    @test lineage[end] == human
    @test lineage[:species] == human
    @test lineage[1:9] == Lineage(Taxon(7711,db))
    @test lineage[All()] == lineage
    @test lineage[Between(1,9)] == lineage[1:9]
    @test lineage[Between(:superkingdom,29)] == lineage[3:29]
    @test lineage[Between(3,:family)] == lineage[3:29]
    @test lineage[Between(:superkingdom,:order)] == lineage[3:24]
    @test lineage[From(14)] == lineage[14:32]
    @test lineage[From(:phylum)] == lineage[9:32]
    @test lineage[Until(9)] == lineage[1:9]
    @test lineage[Until(:order)] == lineage[1:24]

    @test get(lineage, 2, nothing) == Taxon(131567,db)
    @test get(lineage, :class, nothing) == Taxon(40674, db)
    @test get(lineage, 99, nothing) === nothing
    @test get(lineage, :strain, nothing) === nothing
    @test sprint(io -> print_lineage(io, lineage)) == "root;cellular organisms;Eukaryota;Opisthokonta;Metazoa;Eumetazoa;Bilateria;Deuterostomia;Chordata;Craniata;Vertebrata;Gnathostomata;Teleostomi;Euteleostomi;Sarcopterygii;Dipnotetrapodomorpha;Tetrapoda;Amniota;Mammalia;Theria;Eutheria;Boreoeutheria;Euarchontoglires;Primates;Haplorrhini;Simiiformes;Catarrhini;Hominoidea;Hominidae;Homininae;Homo;Homo sapiens"
    @test sprint(io -> print_lineage(io, lineage; delim="+")) == "root+cellular organisms+Eukaryota+Opisthokonta+Metazoa+Eumetazoa+Bilateria+Deuterostomia+Chordata+Craniata+Vertebrata+Gnathostomata+Teleostomi+Euteleostomi+Sarcopterygii+Dipnotetrapodomorpha+Tetrapoda+Amniota+Mammalia+Theria+Eutheria+Boreoeutheria+Euarchontoglires+Primates+Haplorrhini+Simiiformes+Catarrhini+Hominoidea+Hominidae+Homininae+Homo+Homo sapiens"

    reformated = reformat(lineage,[:superkingdom,:phylum,:class,:order,:family,:genus,:species])
    @test reformated[1] == Taxon(2759, db)
    @test reformated[3] == Taxon(40674, db)
    @test reformated[7] == Taxon(9606, db)
    @test sprint(io -> print_lineage(io,reformated) ) == "Eukaryota;Chordata;Mammalia;Primates;Hominidae;Homo;Homo sapiens"

    primate = Taxon(9443,db)
    reformated_1 = reformat(Lineage(primate),[:superkingdom,:phylum,:class,:order,:family,:genus,:species])
    @test reformated_1[7] == UnclassifiedTaxon(:species, primate)
    @test sprint(io -> print_lineage(io,reformated_1)) == "Eukaryota;Chordata;Mammalia;Primates"
    @test sprint(io -> print_lineage(io,reformated_1; fill=true)) == "Eukaryota;Chordata;Mammalia;Primates;unclassified Primates family;unclassified Primates genus;unclassified Primates species"
end