using Taxonomy
using Taxonomy.AbstractTrees
using Test

@testset "dabase.jl" begin
    @test isnothing(current_db())

    db = Taxonomy.DB("db/nodes.dmp", "db/names.dmp")
    @test current_db() == db

    db_1 = Taxonomy.DB("db_1/nodes.dmp", "db_1/names.dmp")
    current_db!(db_1)
    @test current_db() == db_1
end

db = Taxonomy.DB("db/nodes.dmp", "db/names.dmp")

@testset "taxon.jl" begin
    human = Taxon(9606,db)
    @test @inferred(taxid(human)) == 9606
    @test @inferred(name(human)) == "Homo sapiens"
    @test @inferred(rank(human)) == :species
    @test @inferred(sprint(io -> show(io, human))) == "9606 [species] Homo sapiens"

    @test @inferred(Nothing, get(db, 9606, nothing)) == human
    @test Taxon("Homo", db) == Taxon(9605, db)

    @test @inferred(Nothing, AbstractTrees.parent(human)) == Taxon(9605,db)
    @test @inferred(Set(children(human))) == Set([Taxon(63221,db), Taxon(741158, db)])
    denisova = Taxon(741158, db)
    @test @inferred(children(denisova)) == Taxon[]
    @test @inferred(isempty(children(denisova)))

    unclassified_human_subspecies = UnclassifiedTaxon(:subspecies, human)
    @test typeof(unclassified_human_subspecies) == UnclassifiedTaxon
    @test @inferred(name(unclassified_human_subspecies)) == "unclassified Homo sapiens subspecies"
    @test @inferred(rank(unclassified_human_subspecies)) == :subspecies
    @test @inferred(source(unclassified_human_subspecies)) == human
    @test @inferred(sprint(io -> show(io, unclassified_human_subspecies))) == "Unclassified [subspecies] unclassified Homo sapiens subspecies"

    @test @inferred(rank(unclassified_human_subspecies)) == unclassified_human_subspecies.rank

    @test_throws KeyError Taxon(99999999, db)
    @test get(db, 9999999, nothing) === nothing
end

@testset "AbstractTrees.jl" begin
    human = Taxon(9606,db)
    @test treesize(human) == 3
    @test treebreadth(human) == 2
    @test treeheight(human) == 1

    denisova = Taxon(741158, db)
    neanderthalensis = Taxon(63221, db)
    
    @test ischild(denisova, human)
    @test !ischild(neanderthalensis, denisova)
    @test !ischild(human, denisova)

    @test isdescendant(denisova, human)
    @test !isdescendant(neanderthalensis, denisova)
    @test !isdescendant(human, denisova)

    @test eltype(PreOrderDFS(human)) == Taxon
    @test Set([n for n in PreOrderDFS(human)]) == Set([human, neanderthalensis, denisova])
    @test Set([n for n in PostOrderDFS(human)]) == Set([neanderthalensis, denisova, human])
    @test Set([n for n in Leaves(human)]) == Set([neanderthalensis, denisova])
end

@testset "rank.jl" begin
    human = Taxon(9606, db)
    denisova = Taxon(741158, db)
    homininae = Taxon(314295, db)

    @test Rank(:strain) < Rank(:species) < Rank(:genus)
    @test human < Rank(:genus)
    @test human <= Rank(:species)
    @test human <= Rank(:genus)
    @test !(human < Rank(:species))
    @test denisova < Rank(:species)
    @test homininae < Rank(:order)
    @test !(homininae < Rank(:species))
    
    unclassified_human_subspecies = UnclassifiedTaxon(:subspecies, human)
    @test unclassified_human_subspecies < Rank(:species)
end

@testset "lineage.jl" begin
    human = Taxon(9606,db)
    lineage = Lineage(human)
    @test eltype(lineage) == Taxon
    @test lineage[1] == Taxon(1,db)
    @test size(lineage) == (32,)
    @test lineage[32] == lineage[end] == lineage[:species] == human
    @test lineage[1:9] == lineage[Between(1, 9)]
    @test lineage[All()] == lineage
    @test lineage[All(3, 24, 29)] == lineage[Cols(3, 24, 29)] == lineage[Cols(:superkingdom, 24, 29)] == lineage[Cols(:superkingdom, :order, :family)] 
    @test lineage[Between(3, 29)] == lineage[Between(:superkingdom, 29)] == lineage[Between(3, :family)] == lineage[Between(:superkingdom, :family)]
    @test lineage[From(9)] == lineage[From(:phylum)] == lineage[From("phylum")] == lineage[9:32]
    @test lineage[Until(24)] == lineage[Until(:order)] == lineage[Until("order")] == lineage[1:24]

    @test get(lineage, 2, nothing) == Taxon(131567,db)
    @test get(lineage, :class, nothing) == Taxon(40674, db)
    @test get(lineage, 99, nothing) === nothing
    @test get(lineage, :strain, nothing) === nothing
    @test_throws LineageIndexError lineage[Cols(24, 3, 29)]
    @test_throws LineageIndexError lineage[Cols(:order, 3, 29)]
    @test_throws LineageIndexError lineage[Cols(:order, :superkingdom, :family)]

    @test sprint(io -> print_lineage(io, human)) == "root;cellular organisms;Eukaryota;Opisthokonta;Metazoa;Eumetazoa;Bilateria;Deuterostomia;Chordata;Craniata;Vertebrata;Gnathostomata;Teleostomi;Euteleostomi;Sarcopterygii;Dipnotetrapodomorpha;Tetrapoda;Amniota;Mammalia;Theria;Eutheria;Boreoeutheria;Euarchontoglires;Primates;Haplorrhini;Simiiformes;Catarrhini;Hominoidea;Hominidae;Homininae;Homo;Homo sapiens"
    @test sprint(io -> print_lineage(io, human; delim="+")) == "root+cellular organisms+Eukaryota+Opisthokonta+Metazoa+Eumetazoa+Bilateria+Deuterostomia+Chordata+Craniata+Vertebrata+Gnathostomata+Teleostomi+Euteleostomi+Sarcopterygii+Dipnotetrapodomorpha+Tetrapoda+Amniota+Mammalia+Theria+Eutheria+Boreoeutheria+Euarchontoglires+Primates+Haplorrhini+Simiiformes+Catarrhini+Hominoidea+Hominidae+Homininae+Homo+Homo sapiens"
    @test sprint(io -> print_lineage(io, lineage)) == "root;cellular organisms;Eukaryota;Opisthokonta;Metazoa;Eumetazoa;Bilateria;Deuterostomia;Chordata;Craniata;Vertebrata;Gnathostomata;Teleostomi;Euteleostomi;Sarcopterygii;Dipnotetrapodomorpha;Tetrapoda;Amniota;Mammalia;Theria;Eutheria;Boreoeutheria;Euarchontoglires;Primates;Haplorrhini;Simiiformes;Catarrhini;Hominoidea;Hominidae;Homininae;Homo;Homo sapiens"
    @test sprint(io -> print_lineage(io, lineage; delim="+")) == "root+cellular organisms+Eukaryota+Opisthokonta+Metazoa+Eumetazoa+Bilateria+Deuterostomia+Chordata+Craniata+Vertebrata+Gnathostomata+Teleostomi+Euteleostomi+Sarcopterygii+Dipnotetrapodomorpha+Tetrapoda+Amniota+Mammalia+Theria+Eutheria+Boreoeutheria+Euarchontoglires+Primates+Haplorrhini+Simiiformes+Catarrhini+Hominoidea+Hominidae+Homininae+Homo+Homo sapiens"

    reformated_human_lineage = reformat(lineage,[:superkingdom,:phylum,:class,:order,:family,:genus,:species])
    @test_throws LineageIndexError reformat(lineage,[:species, :superkingdom,:phylum,:class,:order,:family,:genus])
    @test isformatted(reformated_human_lineage)
    @test_throws LineageReformatError reformat(reformated_human_lineage, [:superkingdom])
    @test eltype(reformated_human_lineage) == Taxon
    @test reformated_human_lineage[1] == Taxon(2759, db)
    @test reformated_human_lineage[3] == Taxon(40674, db)
    @test reformated_human_lineage[7] == Taxon(9606, db)
    @test sprint(io -> print_lineage(io, reformated_human_lineage) ) == "Eukaryota;Chordata;Mammalia;Primates;Hominidae;Homo;Homo sapiens"

    primate = Taxon(9443,db)
    reformated_primate_lineage = reformat(Lineage(primate), [:superkingdom,:phylum,:class,:order,:family,:genus,:species])
    @test eltype(reformated_primate_lineage) == Union{Taxon, UnclassifiedTaxon}
    @test reformated_primate_lineage[7] == UnclassifiedTaxon(:species, primate)
    @test sprint(io -> print_lineage(io, reformated_primate_lineage)) == "Eukaryota;Chordata;Mammalia;Primates;;;"
    @test sprint(io -> print_lineage(io, reformated_primate_lineage; skip=true)) == "Eukaryota;Chordata;Mammalia;Primates"
    @test sprint(io -> print_lineage(io, reformated_primate_lineage; fill=true)) == "Eukaryota;Chordata;Mammalia;Primates;unclassified Primates family;unclassified Primates genus;unclassified Primates species"

    co = Taxon(131567,db)
    reformated_co_lineage = reformat(Lineage(co), [:superkingdom,:phylum,:class,:order,:family,:genus,:species])
    @test reformated_co_lineage[7] == UnclassifiedTaxon(:species, co)
    @test sprint(io -> print_lineage(io, reformated_co_lineage)) == ";;;;;;"
    @test sprint(io -> print_lineage(io, reformated_co_lineage; skip=true)) == ""
    @test sprint(io -> print_lineage(io, reformated_co_lineage; fill=true)) == "unclassified cellular organisms superkingdom;unclassified cellular organisms phylum;unclassified cellular organisms class;unclassified cellular organisms order;unclassified cellular organisms family;unclassified cellular organisms genus;unclassified cellular organisms species"

    human = Taxon(9606,db)
    primate = Taxon(9443,db)
    @test @inferred(isdescendant(human, primate))
    @test @inferred(isancestor(primate, human))
end

@testset "lca.jl" begin
    human = Taxon(9606, db)
    gorilla = Taxon(9593, db)
    pan = Taxon(9598, db)
    @test lca([human,gorilla]) == lca(human,gorilla) == Taxon(207598, db)
    @test lca([human,gorilla,pan]) == lca(human,gorilla,pan) == Taxon(207598, db)
end