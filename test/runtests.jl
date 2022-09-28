using Taxonomy
using Taxonomy.AbstractTrees
using Test

db = Taxonomy.DB("db/nodes.dmp", "db/names.dmp")

@testset "taxon.jl" begin
    @test Taxon <: AbstractTaxon
    @test UnclassifiedTaxon <: AbstractTaxon

    human = Taxon(9606,db)
    @test typeof(human) == Taxon
    @test taxid(human) == 9606
    @test name(human) == "Homo sapiens"
    @test rank(human) == :species
    @test sprint(io -> show(io, human)) == "9606 [species] Homo sapiens"

    @test get(db, 9606, nothing) == human

    @test AbstractTrees.parent(human) == Taxon(9605,db)
#    @test children(human) == [Taxon(741158,db), Taxon(63221,db)]
    denisova = Taxon(741158, db)
    @test children(denisova) == Taxon[]
    @test isempty(children(denisova))

    unclassified_human_subspecies = UnclassifiedTaxon(:subspecies, human)
    @test typeof(unclassified_human_subspecies) == UnclassifiedTaxon
    @test name(unclassified_human_subspecies) == "unclassified Homo sapiens subspecies"
    @test rank(unclassified_human_subspecies) == :subspecies
    @test source(unclassified_human_subspecies) == human
    @test sprint(io -> show(io, unclassified_human_subspecies)) == "Unclassified [subspecies] unclassified Homo sapiens subspecies"

    @test rank(unclassified_human_subspecies) == unclassified_human_subspecies.rank

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
    @test [n for n in PreOrderDFS(human)] == [human, denisova, neanderthalensis]
    @test [n for n in PostOrderDFS(human)] == [denisova, neanderthalensis, human]
    @test [n for n in Leaves(human)] == [denisova, neanderthalensis]
end

@testset "rank.jl" begin
    human = Taxon(9606, db)
    denisova = Taxon(741158, db)
    homininae = Taxon(314295, db)

    @test Rank(:strain) < Rank(:species) < Rank(:genus)
    @test human < Rank(:genus)
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
    @test lineage[1] == Taxon(1,db)
    @test size(lineage) == (32,)
    @test lineage[32] == lineage[end] == lineage[:species] == human
    @test lineage[1:9] == lineage[Between(1, 9)]
    @test lineage[All()] == lineage
    @test lineage[Between(3, 29)] == lineage[Between(:superkingdom, 29)] == lineage[Between(3, :family)] == lineage[Between(:superkingdom, :family)]
    @test lineage[From(9)] == lineage[From(:phylum)] == lineage[9:32]
    @test lineage[Until(24)] == lineage[Until(:order)] == lineage[1:24]

    @test get(lineage, 2, nothing) == Taxon(131567,db)
    @test get(lineage, :class, nothing) == Taxon(40674, db)
    @test get(lineage, 99, nothing) === nothing
    @test get(lineage, :strain, nothing) === nothing

    @test sprint(io -> print_lineage(io, human)) == "root;cellular organisms;Eukaryota;Opisthokonta;Metazoa;Eumetazoa;Bilateria;Deuterostomia;Chordata;Craniata;Vertebrata;Gnathostomata;Teleostomi;Euteleostomi;Sarcopterygii;Dipnotetrapodomorpha;Tetrapoda;Amniota;Mammalia;Theria;Eutheria;Boreoeutheria;Euarchontoglires;Primates;Haplorrhini;Simiiformes;Catarrhini;Hominoidea;Hominidae;Homininae;Homo;Homo sapiens"
    @test sprint(io -> print_lineage(io, human; delim="+")) == "root+cellular organisms+Eukaryota+Opisthokonta+Metazoa+Eumetazoa+Bilateria+Deuterostomia+Chordata+Craniata+Vertebrata+Gnathostomata+Teleostomi+Euteleostomi+Sarcopterygii+Dipnotetrapodomorpha+Tetrapoda+Amniota+Mammalia+Theria+Eutheria+Boreoeutheria+Euarchontoglires+Primates+Haplorrhini+Simiiformes+Catarrhini+Hominoidea+Hominidae+Homininae+Homo+Homo sapiens"
    @test sprint(io -> print_lineage(io, lineage)) == "root;cellular organisms;Eukaryota;Opisthokonta;Metazoa;Eumetazoa;Bilateria;Deuterostomia;Chordata;Craniata;Vertebrata;Gnathostomata;Teleostomi;Euteleostomi;Sarcopterygii;Dipnotetrapodomorpha;Tetrapoda;Amniota;Mammalia;Theria;Eutheria;Boreoeutheria;Euarchontoglires;Primates;Haplorrhini;Simiiformes;Catarrhini;Hominoidea;Hominidae;Homininae;Homo;Homo sapiens"
    @test sprint(io -> print_lineage(io, lineage; delim="+")) == "root+cellular organisms+Eukaryota+Opisthokonta+Metazoa+Eumetazoa+Bilateria+Deuterostomia+Chordata+Craniata+Vertebrata+Gnathostomata+Teleostomi+Euteleostomi+Sarcopterygii+Dipnotetrapodomorpha+Tetrapoda+Amniota+Mammalia+Theria+Eutheria+Boreoeutheria+Euarchontoglires+Primates+Haplorrhini+Simiiformes+Catarrhini+Hominoidea+Hominidae+Homininae+Homo+Homo sapiens"

    reformated_human_lineage = reformat(lineage,[:superkingdom,:phylum,:class,:order,:family,:genus,:species])
    @test reformated_human_lineage[1] == Taxon(2759, db)
    @test reformated_human_lineage[3] == Taxon(40674, db)
    @test reformated_human_lineage[7] == Taxon(9606, db)
    @test sprint(io -> print_lineage(io, reformated_human_lineage) ) == "Eukaryota;Chordata;Mammalia;Primates;Hominidae;Homo;Homo sapiens"

    primate = Taxon(9443,db)
    reformated_primate_lineage = reformat(Lineage(primate), [:superkingdom,:phylum,:class,:order,:family,:genus,:species])
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
    @test isdescendant(human, primate)
    @test isancestor(primate, human)
end

@testset "lca.jl" begin
    human = Taxon(9606, db)
    gorilla = Taxon(9593, db)
    pan = Taxon(9598, db)
    @test lca([human,gorilla]) == lca(human,gorilla) == Taxon(207598, db)
    @test lca([human,gorilla,pan]) == lca(human,gorilla,pan) == Taxon(207598, db)
end