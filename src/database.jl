const default_db_size = 2500000

struct DB
    nodes_dmp::String
    names_dmp::String
    parents::Dict{Int,Int}
    ranks::Dict{Int,Symbol}
    names::Dict{Int,String}
end

Base.show(io::IO, db::DB) = print(io, "Taxonomy.DB(\"$(db.nodes_dmp)\",\"$(db.names_dmp)\")")

"""
    Taxonomy.DB

# Constructors
```julia
DB(nodes_dmp::String, names_dmp::String)
DB(db_path::String, nodes_dmp::String, names_dmp::String)
```
Create DB(taxonomy database) object from nodes.dmp and names.dmp files.
You can specify the paths of the nodes.dmp and names.dmp files, or the directory where they exist and the names.
"""

function DB(nodes_dmp::String, names_dmp::String)
    @assert isfile(nodes_dmp)
    @assert isfile(names_dmp)

    t1 = @async importnodes(nodes_dmp)
    t2 = @async importnames(names_dmp)

    parents, ranks = fetch(t1)
    namaes = fetch(t2)
    return DB(nodes_dmp, names_dmp, parents, ranks, namaes)
end

function DB(db_path::String, nodes_dmp::String, names_dmp::String)
    @assert ispath(db_path)

    nodes_dmp_path = joinpath(db_path, nodes_dmp)
    names_dmp_path = joinpath(db_path, names_dmp)

    return DB(nodes_dmp_path, names_dmp_path)
end

function importnodes(nodes_dmp_path::String; db_size::Int=default_db_size)
    parents = Vector{Tuple{Int,Int}}(undef, db_size)
    ranks = Vector{Tuple{Int, Symbol}}(undef, db_size)

    f = open(nodes_dmp_path, "r")
    c = 0
    for line in eachline(f)
        cols = split(line, "\t", limit=6)
        @assert length(cols) > 5
        @inbounds taxid = parse(Int, cols[1])
        @inbounds parent = parse(Int, cols[3])
        @inbounds rank = Symbol(cols[5])

        parent != taxid || continue
            
        c += 1
        @inbounds parents[c] = (taxid, parent)
        @inbounds ranks[c] = (taxid, rank)
    end
    resize!(parents, c)
    resize!(ranks, c)
    close(f)
    return Dict(parents), Dict(ranks)
end

function importnames(names_dmp_path::String; db_size::Int=default_db_size)
    namaes = Vector{Tuple{Int,String}}(undef, db_size)

    f = open(names_dmp_path, "r")
    c = 0
    for line in eachline(f)
        cols = split(line, "\t", limit=8)
        @assert length(cols) > 7
        if @inbounds cols[7] == "scientific name"
            @inbounds taxid = parse(Int, cols[1])
            @inbounds name = cols[3]

            c+=1
            @inbounds namaes[c] = (taxid, name)
        end
    end
    close(f)
    resize!(namaes, c)
    return Dict(namaes)
end