const TaxonOrUnclassifiedTaxon = Union{Taxon, UnclassifiedTaxon}

struct LineageReformatError <: Exception end

Base.showerror(io::IO, ::LineageReformatError) = print(io, "It is already reformatted.")

_LR() = throw(LineageReformatError())

struct LineageIndexError <: Exception end

Base.showerror(io::IO, ::LineageIndexError) = print(io, "The index order is messed up.")

_LI() = throw(LineageIndexError())

"""
    Lineage{T<:AbstractTaxon} <: AbstractVector{T}

A type that stores lineage information in `Vector`-like format.
`T` represents element types, `Taxon` or `UnclassifiedTaxon`.

- `getindex` is overloaded to get `Taxon` values. `Symbol`s such as `:superkingdom`, `:family`, `:genus`, `:species` in `CanonicalRanks` can be used. Also, `Between`, `From`, `Until`, `Cols` and `All` selectors can be used in more complex rank selection scenarios.
- Once reformatted, it cannot be reformatted again. The status can be checked using `isreformatted(lineage)`.
"""
struct Lineage{T<:AbstractTaxon} <: AbstractVector{T}
    line::Vector{T}
    index::OrderedDict{Symbol,Int}
    reformatted::Bool
end

function Lineage(taxon::Taxon)
    line = Taxon[]
    ranks = Symbol[]
    rankpos = Int[]
    current_taxon = taxon
    pos = 0
    while true
        pos += 1
        push!(line, current_taxon)
        current_rank = rank(current_taxon)
        if current_rank in CanonicalRanks
            ranks = push!(ranks, current_rank)
            rankpos = push!(rankpos, pos)
        end
        current_taxon = AbstractTrees.parent(current_taxon)
        isnothing(current_taxon) && break
    end
    reverse!(line)
    reverse!(ranks)
    reverse!(rankpos)
    rankpos = length(line) + 1 .- rankpos
    return Lineage(line, OrderedDict(Pair.(ranks, rankpos)), false)
end

"""
    isreformatted(lineage::Lineage)

Return `true` if `lineage` is already reformatted.
"""
isreformatted(lineage::Lineage) = lineage.reformatted

Base.IndexStyle(::Lineage) = IndexLinear()
Base.size(l::Lineage) = size(l.line)
Base.getindex(l::Lineage, i::Int) = getindex(l.line, i)
Base.lastindex(l::Lineage) = lastindex(l.line)

function _check_index_order(ranks::Vector{Symbol})
    pseudo_index = .- Integer.(Rank.(ranks))
    _check_index_order(pseudo_index)
end

function _check_index_order(ranks::Vector{Int})
    flag = true
    (p, rest) = Iterators.peel(ranks)
    for r in rest
        flag &= p <= r
        p = r
    end
    flag ? (return nothing) : _LI()
end

Base.getindex(l::Lineage, s::Symbol) = l.line[l.index[s]]

function Base.getindex(l::Lineage, range::UnitRange{Int})
    line = getindex.(Ref(l), range)
    index = OrderedDict(rank(t) => i for (i, t) in enumerate(line) if in(rank(t), CanonicalRanks))
    return Lineage(line, index, true)
end

Base.getindex(l::Lineage, idx::All) = isempty(idx.cols) ? l : getindex(l, Cols(idx.cols...))

function Base.getindex(l::Lineage{T}, idx::Cols) where T
    index = map(collect(idx.cols)) do i
        i isa Symbol ? l.index[i] : i
    end
    _check_index_order(index)

    line = getindex.(Ref(l), index)
    index = OrderedDict(rank(t) => i for (i, t) in enumerate(line) if in(rank(t), CanonicalRanks))
    return Lineage(line, index, true)
end

Base.getindex(l::Lineage, idx::Between{Int,Int}) = l[idx.first:idx.last]
Base.getindex(l::Lineage, idx::Between{Symbol,Int}) = getindex(l, Between(l.index[idx.first], idx.last))
Base.getindex(l::Lineage, idx::Between{Int,Symbol}) = getindex(l, Between(idx.first, l.index[idx.last]))
Base.getindex(l::Lineage, idx::Between{Symbol,Symbol}) = getindex(l, Between(l.index[idx.first], l.index[idx.last]))
Base.getindex(l::Lineage, idx::From{Int}) = l[idx.first:end]
Base.getindex(l::Lineage, idx::From{Symbol}) = getindex(l, From(l.index[idx.first]))
Base.getindex(l::Lineage, idx::Until{Int}) = l[1:idx.last]
Base.getindex(l::Lineage, idx::Until{Symbol}) = getindex(l, Until(l.index[idx.last]))

"""
    get(db::Taxonomy.DB, idx::Union{Int,Symbol}, default)

Return the Taxon object stored for the given taxid or rank (i.e. :phylum), or the given default value if no mapping for the taxid is present.
"""
function Base.get(l::Lineage, idx::Union{Int,Symbol}, default::Any)
    try
        return getindex(l,idx)
    catch
        return default
    end
end

"""
    reformat(l::Lineage, ranks::Vector{Symbol})

Return the `Lineage` object reformatted according to the given ranks.
If there id no corresponding taxon in the lineage to the rank, `UnclassifiedTaxon` will be stored.
Once a `Lineage` is reformatted, it cannot be reformatted again.
"""
function reformat(l::Lineage, ranks::Vector{Symbol})
    _check_index_order(ranks)

    if isreformatted(l)
        _LR()
    end

    len = length(ranks)
    line = Vector{TaxonOrUnclassifiedTaxon}(undef, len)
    previous_ranks = first.(collect(l.index))

    if isempty(previous_ranks)
        ut_source = l[end]
    end

    for (i, rank) in enumerate(ranks)
        if rank in previous_ranks
            taxon = getindex(l, rank)
            if taxon isa UnclassifiedTaxon
                taxon = UnclassifiedTaxon(rank, ut_source)
            end
        else
            taxon = UnclassifiedTaxon(rank, ut_source)
        end
        ut_source = taxon
        line[i] = taxon
    end
    if all(isa.(line, Taxon))
        line = convert.(Taxon, line)
    end
    return Lineage(line, OrderedDict(Pair.(ranks, 1:len)), true)
end

"""
    namedtuple(lineage::Lineage; kwargs...)

Return a NamedTuple whose filednames is ranks (in the `CanonicalRanks`) of the `lineage`.
This function is useful for converting `Lineage` to `DataFrame`, for example.

# Arguments

* `fill_by_missing::Bool = false` - If `true`, fills missing instead of `UnclassifiedTaxon`.
"""
function namedtuple(l::Lineage; fill_by_missing::Bool=false)
    ranks = first.(collect(l.index))
    values = getindex.(Ref(l), ranks)
    if fill_by_missing
        values = map(values) do val
            val isa UnclassifiedTaxon ? missing : val
        end
    end
    return NamedTuple{Tuple(ranks)}(values)
end

"""
    print_lineage(lineage::Lineage; kwargs...)
    print_lineage(io::IO, lineage::Lineage; kwargs...)

Print a formatted representation of the lineage to the given `IO` object.

# Arguments

* `delim::AbstractString = ";"` - The delimiter between taxon fields.
* `fill::Bool = false` - If `true`, prints `UnclassifiedTaxon`. only availavle when skip is false.
* `skip::Bool = false` - If `true`, skip printing `UnclassifiedTaxon` and delimiter.
"""
function print_lineage(io::IO, lineage::Lineage; delim::AbstractString=";", fill::Bool=false, skip::Bool=false)
    taxa = collect(lineage)
    skip && filter!(taxon -> !(taxon isa UnclassifiedTaxon), taxa)

    names = map(taxa) do taxon
        if taxon isa UnclassifiedTaxon
            fill ? name(taxon) : ""
        else
            name(taxon)
        end
    end

    l = join(names, delim)
    print(io, l)
    return nothing
end

print_lineage(lineage::Lineage; kwargs...) = print_lineage(stdout::IO, lineage; kwargs...)
print_lineage(io::IO, taxon::Taxon; kwargs...) = print_lineage(io, Lineage(taxon); kwargs...)
print_lineage(taxon::Taxon; kwargs...) = print_lineage(stdout::IO, Lineage(taxon);kwargs...)

Base.show(io::IO, lineage::Lineage) = print_lineage(io, lineage)

"""
    isdescendant(descendant::Taxon, ancestor::Taxon)

Return `true` if the former taxon is a descendant of the latter taxon.
"""
AbstractTrees.isdescendant(descendant::Taxon, ancestor::Taxon) = ancestor in Lineage(descendant)

"""
    isancestor(ancestor::Taxon, descendant::Taxon)

Return `true` if the former taxon is an ancestor of the latter taxon.
"""
isancestor(ancestor::Taxon, descendant::Taxon) = AbstractTrees.isdescendant(descendant, ancestor)
