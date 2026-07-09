const default_db_sizehint = 4000000

"""
    Taxonomy.DB

# Constructors

```julia
DB(nodes_dmp::String, names_dmp::String)
```

Create DB(taxonomy database) object from nodes.dmp and names.dmp files.

# Examples

```jldoctest
julia> nodes_dmp = joinpath(_DOCTEST_DB_DIR, "nodes.dmp");

julia> names_dmp = joinpath(_DOCTEST_DB_DIR, "names.dmp");

julia> db = Taxonomy.DB(nodes_dmp, names_dmp);

julia> current_db() === db
true

julia> taxid(Taxon(9606, db))
9606
```
"""
struct DB
    nodes_dmp::String
    names_dmp::String
    parents::Dict{Int,Int}
    ranks::Dict{Int,Symbol}
    names::Dict{Int,String}
    name2taxids::Ref{Union{Nothing, Dict{String, Vector{Int}}}}
    children::Ref{Union{Nothing, Dict{Int, Vector{Int}}}}
    function DB(nodes_dmp::String, names_dmp::String)
        isfile(nodes_dmp) || throw(ArgumentError("nodes_dmp file does not exist: $nodes_dmp"))
        isfile(names_dmp) || throw(ArgumentError("names_dmp file does not exist: $names_dmp"))

        parents, ranks = importnodes(nodes_dmp)
        names = importnames(names_dmp)

        name2taxids = Ref{Union{Nothing, Dict{String, Vector{Int}}}}(nothing)
        children = Ref{Union{Nothing, Dict{Int, Vector{Int}}}}(nothing)
        db = new(nodes_dmp, names_dmp, Dict(parents), Dict(ranks), Dict(names), name2taxids, children)
        current_db!(db)
        return db
    end
end

Base.show(io::IO, db::DB) = print(io, "Taxonomy.DB(\"$(db.nodes_dmp)\",\"$(db.names_dmp)\")")

function importnodes(nodes_dmp_path::String; sizehint::Int=default_db_sizehint)
    taxids = Int[]
    parents = Int[]
    ranks = Symbol[]
    sizehint!(taxids, sizehint)
    sizehint!(parents, sizehint)
    sizehint!(ranks, sizehint)

    open(nodes_dmp_path, "r") do f
        for line in eachline(f)
            cols = split(line, "\t", limit=6)

            push!(taxids, parse(Int, cols[1]))
            push!(parents, parse(Int, cols[3]))
            push!(ranks, Symbol(cols[5]))
        end
    end
    return Pair{Int, Int}.(taxids, parents), Pair{Int, Symbol}.(taxids, ranks)
end

function importnames(names_dmp_path::String; sizehint::Int=default_db_sizehint)
    taxids = Int[]
    names = String[]
    sizehint!(taxids, sizehint)
    sizehint!(names, sizehint)

    open(names_dmp_path, "r") do f
        for line in eachline(f)
            cols = split(line, "\t", limit=8)
            cols[7] != "scientific name" && continue

            push!(taxids, parse(Int, cols[1]))
            push!(names, String(cols[3]))
        end
    end
    return Pair{Int, String}.(taxids, names)
end

const _current_db = Ref{Union{Nothing, DB}}(nothing)
"""
    current_db()

Return the current active database or the last database that got created.

# Examples

```jldoctest
julia> current_db() === db
true
```
"""
function current_db()
    if isnothing(_current_db[])
        error("Taxonomy.DB is not found. Please run Taxonomy.DB(nodes_dmp::String, names_dmp::String) before proceeding")
    end
    _current_db[]
end

function name2taxids_db!(db::DB)::Dict{String, Vector{Int}}
    mapping = Dict{String, Vector{Int}}()
    for (taxid, name) in db.names
        push!(get!(mapping, name, Int[]), taxid)
    end
    db.name2taxids[] = mapping
    return mapping
end

function name2taxids_db(db::DB)::Dict{String, Vector{Int}}
    mapping = db.name2taxids[]
    if isnothing(mapping)
        return name2taxids_db!(db)
    end
    return mapping
end

function children_db!(db::DB)::Dict{Int, Vector{Int}}
    mapping = Dict{Int, Vector{Int}}()
    for (taxid, parent) in db.parents
        taxid == parent && continue
        push!(get!(mapping, parent, Int[]), taxid)
    end
    db.children[] = mapping
    return mapping
end

function children_db(db::DB)::Dict{Int, Vector{Int}}
    mapping = db.children[]
    if isnothing(mapping)
        return children_db!(db)
    end
    return mapping
end

"""
    current_db!(db::Taxonomy.DB)

Set `db` as the current active database.

# Examples

```jldoctest
julia> current_db!(db) === db
true

julia> current_db() === db
true
```
"""
function current_db!(db::DB)
    _current_db[] = db
    return db
end
