const default_db_size = 4000000

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

        parents, ranks = importnodes(nodes_dmp)
        names = importnames(names_dmp)

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

    f = open(names_dmp_path, "r")
    c = 0
    for line in eachline(f)
        cols = split(line, "\t", limit=8)
        cols[7] != "scientific name" && continue
    
        c+=1
        @inbounds taxids[c] = parse(Int, cols[1])
        @inbounds names[c] = String(cols[3])
    end
    resize!(taxids, c)
    resize!(names, c)
    close(f)
    return Pair{Int, String}.(taxids, names)
end

const _current_db = Ref{Union{Nothing, DB}}(nothing)
"""
    current_db()

Return the current active database or the last database that got created.
"""
function current_db()
    if isnothing(_current_db[])
        error("Taxonomy.DB is not found. Please run Taxonomy.DB(nodes_dmp::String, names_dmp::String) before proceeding")
    end
    _current_db[]
end

const _current_name2taxids_db = Ref{Union{Nothing, Dict{String, Vector{Int}}}}(nothing)
"""
    current_name2taxids_db!()

(Re)build and cache an inverted mapping from **scientific name** → **Vector{Int}**
for the active taxonomy database returned by `current_db()`.

Returns the freshly-built dictionary.
"""
function current_name2taxids_db!()
    db = current_db()                 # throws if no DB active

    mapping = Dict{String, Vector{Int}}()
    for (taxid, name) in db.names
        push!(get!(mapping, name, Int[]), taxid)
    end

    _current_name2taxids_db[] = mapping
    return mapping
end

"""
    current_name2taxids_db()

Return the cached **name ⇒ taxids** dictionary.  If the cache has not yet been
built — i.e. `_current_name2taxids[] === nothing` — an informative `error` is
thrown so that the caller explicitly decides when to rebuild via
`current_name2taxids_db!()`.
"""
function current_name2taxids_db()
    if isnothing(_current_name2taxids_db[])
        current_name2taxids_db!()
    end
    return _current_name2taxids_db[]
end

"""
    current_db!(db::Taxonomy.DB)

Set `db` as the current active database.
Must call `current_name2taxids_db!()` again for the new DB. 
"""
function current_db!(db::DB)
    _current_db[] = db
    _current_name2taxids_db[] = nothing   # error on access until rebuilt
    return db
end
