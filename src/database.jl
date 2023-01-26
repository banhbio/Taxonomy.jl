const default_db_size = 2500000

"""
    Taxonomy.DB

# Constructors
```julia
DB(nodes_dmp::String, names_dmp::String)
```
Create DB(taxonomy database) object from nodes.dmp and names.dmp files.
"""
struct DB
    nodes_dmp::String
    names_dmp::String
    parents::Dict{Int,Int}
    ranks::Dict{Int,Symbol}
    names::Dict{Int,String}
    function DB(nodes_dmp::String, names_dmp::String)
        @assert isfile(nodes_dmp)
        @assert isfile(names_dmp)

        _nodes = Threads.@spawn importnodes(nodes_dmp)
        _names = Threads.@spawn importnames(names_dmp)

        parents, ranks = fetch(_nodes)
        names = fetch(_names)

        db = new(nodes_dmp, names_dmp, Dict(parents), Dict(ranks), Dict(names))
        current_db!(db)
        return db
    end
end

Base.show(io::IO, db::DB) = print(io, "Taxonomy.DB(\"$(db.nodes_dmp)\",\"$(db.names_dmp)\")")

function importnodes(nodes_dmp_path::String; db_size::Int=default_db_size)
    taxids = Vector{Int}(undef, db_size)
    parents = Vector{Int}(undef, db_size)
    ranks = Vector{Symbol}(undef, db_size)

    c = 0
    open(nodes_dmp_path, "r") do f
        for line in eachline(f)
            cols = split(line, "\t", limit=6)
            cols[1] == cols[3] && continue

            taxid = parse(Int, cols[1])
            parent = parse(Int, cols[3])
            rank = Symbol(cols[5])

            c += 1
            @inbounds taxids[c] = taxid
            @inbounds parents[c] = parent
            @inbounds ranks[c] = rank
        end
    end
    resize!(taxids, c)
    resize!(parents, c)
    resize!(ranks, c)
    return Pair{Int, Int}.(taxids, parents), Pair{Int, Symbol}.(taxids, ranks)
end

function importnames(names_dmp_path::String; db_size::Int=default_db_size)
    taxids = Vector{Int}(undef, db_size)
    names = Vector{String}(undef, db_size)

    c = 0
    open(names_dmp_path, "r") do f
        for line in eachline(f)
            cols = split(line, "\t", limit=8)
            cols[7] != "scientific name" && continue

            c+=1
            @inbounds taxids[c] = parse(Int, cols[1])
            @inbounds names[c] = String(cols[3])
        end
    end
    resize!(taxids, c)
    resize!(names, c)
    return Pair{Int, String}.(taxids, names)
end

const _current_db = Ref{Union{Nothing, DB}}(nothing)
"""
    current_db()

Return the current active database or the last database that got created.
"""
current_db() = _current_db[]

"""
    current_db!(db::Taxonomy.DB)

Set `db` as the current active database.
"""
current_db!(db::DB) = (_current_db[] = db)
