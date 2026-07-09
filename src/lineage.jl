const TaxonOrUnclassifiedTaxon = Union{Taxon, UnclassifiedTaxon}

struct LineageReformatError <: Exception end

Base.showerror(io::IO, ::LineageReformatError) = print(io, "It is already reformatted.")

_LR() = throw(LineageReformatError())

struct LineageIndexError <: Exception end

Base.showerror(io::IO, ::LineageIndexError) = print(io, "Lineage ranks or positions must be requested from higher to lower rank.")

_LI() = throw(LineageIndexError())

struct UnCanonicalRankError <: Exception
    ranks::Vector{Symbol}
end

Base.showerror(io::IO, e::UnCanonicalRankError) = print(io, "Non-canonical ranks are not supported in reformat: $(e.ranks)")

struct RankAliasError <: Exception
    ranks::Vector{Symbol}
end

Base.showerror(io::IO, e::RankAliasError) = print(io, "Rank aliases cannot be requested together in reformat: $(e.ranks)")

"""
    Lineage{T<:AbstractTaxon} <: AbstractVector{T}

A type that stores lineage information in `Vector`-like format.
`T` represents element types, `Taxon` or `UnclassifiedTaxon`.

- `getindex` is overloaded to get `Taxon` values. `Symbol`s such as `:domain`, `:superkingdom`, `:realm`, `:family`, `:genus`, `:species` in `CanonicalRanks` can be used. Also, `Between`, `From`, `Until`, `Cols` and `All` selectors can be used in more complex rank selection scenarios.
- Once reformatted, it cannot be reformatted again. The status can be checked using `isreformatted(lineage)`.

# Examples

```jldoctest
julia> lineage = Lineage(Taxon(9606));

julia> lineage[:species]
9606 [species] Homo sapiens

julia> lineage[:class]
40674 [class] Mammalia
```
"""
struct Lineage{T<:AbstractTaxon} <: AbstractVector{T}
    line::Vector{T}
    ranks::Vector{Symbol}
    index::OrderedDict{Int,Int}
    reformatted::Bool
end

_rank_code(rank::Symbol) = Integer(Rank(rank))

function _lineage_index(ranks::Vector{Symbol}, positions)
    return OrderedDict{Int, Int}(Pair.(_rank_code.(ranks), positions))
end

function _canonical_rank_positions(line)
    pos = [(rank(t), i) for (i, t) in enumerate(line) if in(rank(t), CanonicalRanks)]
    return first.(pos), last.(pos)
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
    return Lineage(line, ranks, _lineage_index(ranks, rankpos), false)
end

"""
    isreformatted(lineage::Lineage)

Return `true` if `lineage` is already reformatted.

# Examples

```jldoctest
julia> isreformatted(Lineage(Taxon(9606)))
false

julia> ranks = [:domain, :phylum, :class, :order, :family, :genus, :species];

julia> isreformatted(reformat(Lineage(Taxon(9606)), ranks))
true
```
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

function _check_reformat_ranks(ranks::Vector{Symbol})
    noncanonical = Symbol[]
    rank_codes = Int[]
    for r in ranks
        canonical_rank = Rank(r)
        if canonical_rank isa UnCanonicalRank
            push!(noncanonical, r)
        else
            push!(rank_codes, Integer(canonical_rank))
        end
    end
    isempty(noncanonical) || throw(UnCanonicalRankError(noncanonical))

    seen = Set{Int}()
    aliases = Symbol[]
    for (r, code) in zip(ranks, rank_codes)
        if code in seen
            push!(aliases, r)
        else
            push!(seen, code)
        end
    end
    isempty(aliases) || throw(RankAliasError(ranks))
    return nothing
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

Base.getindex(l::Lineage, s::Symbol) = getindex(l, Rank(s))
Base.getindex(l::Lineage, r::CanonicalRank) = getindex(l, l.index[Integer(r)])
Base.getindex(l::Lineage, ur::UnCanonicalRank) = KeyError(ur) |> throw

function Base.getindex(l::Lineage, range::UnitRange{Int})
    line = getindex.(Ref(l), range)
    ranks, rankpos = _canonical_rank_positions(line)
    index = _lineage_index(ranks, rankpos)
    return Lineage(line, ranks,  index, true)
end

Base.getindex(l::Lineage, idx::All) = l

function Base.getindex(l::Lineage{T}, idx::Cols) where T
    index = map(collect(idx.cols)) do i
        i isa Symbol ? l.index[Integer(Rank(i))] : i
    end
    _check_index_order(index)

    line = getindex.(Ref(l), index)
    ranks, rankpos = _canonical_rank_positions(line)
    index = _lineage_index(ranks, rankpos)
    return Lineage(line, ranks, index, true)
end

Base.getindex(l::Lineage, idx::Between{Int,Int}) = l[idx.first:idx.last]
Base.getindex(l::Lineage, idx::Between{Symbol,Int}) = getindex(l, Between(l.index[Integer(Rank(idx.first))], idx.last))
Base.getindex(l::Lineage, idx::Between{Int,Symbol}) = getindex(l, Between(idx.first, l.index[Integer(Rank(idx.last))]))
Base.getindex(l::Lineage, idx::Between{Symbol,Symbol}) = getindex(l, Between(l.index[Integer(Rank(idx.first))], l.index[Integer(Rank(idx.last))]))
Base.getindex(l::Lineage, idx::From{Int}) = l[idx.first:end]
Base.getindex(l::Lineage, idx::From{Symbol}) = getindex(l, From(l.index[Integer(Rank(idx.first))]))
Base.getindex(l::Lineage, idx::Until{Int}) = l[1:idx.last]
Base.getindex(l::Lineage, idx::Until{Symbol}) = getindex(l, Until(l.index[Integer(Rank(idx.last))]))

"""
    get(lineage::Lineage, idx::Union{Int,Symbol}, default)

Return the `Taxon` object stored at the given position or rank (i.e. `:phylum`), or the given default value if no matching item is present.

# Examples

```jldoctest
julia> lineage = Lineage(Taxon(9606));

julia> get(lineage, :class, nothing)
40674 [class] Mammalia

julia> get(lineage, :strain, nothing) === nothing
true
```
"""
function Base.get(l::Lineage, idx::Union{Int,Symbol}, default::Any)
    try
        return getindex(l,idx)
    catch e
        e isa KeyError || e isa BoundsError || rethrow()
        return default
    end
end

"""
    reformat(l::Lineage, ranks::Vector{Symbol})

Return the `Lineage` object reformatted according to the given canonical ranks.
Non-canonical ranks and multiple aliases for the same rank slot are not supported.
If there is no corresponding taxon in the lineage to the rank, `UnclassifiedTaxon` will be stored.
Once a `Lineage` is reformatted, it cannot be reformatted again.

# Examples

```jldoctest
julia> ranks = [:domain, :phylum, :class, :order, :family, :genus, :species];

julia> reformatted = reformat(Lineage(Taxon(9606)), ranks);

julia> isreformatted(reformatted)
true

julia> taxid.(reformatted)
7-element Vector{Int64}:
  2759
  7711
 40674
  9443
  9604
  9605
  9606
```
"""
function reformat(l::Lineage, ranks::Vector{Symbol})
    _check_reformat_ranks(ranks)
    _check_index_order(ranks)

    isreformatted(l) && _LR()

    len = length(ranks)
    line = Vector{TaxonOrUnclassifiedTaxon}(undef, len)
    previous_ranks = l.ranks
    previuos_ranks_ints = Integer.(Rank.(previous_ranks))

    ut_source = l[end]

    for (i, rank) in enumerate(ranks)
        if Integer(Rank(rank)) in previuos_ranks_ints
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
    return Lineage(line, ranks, _lineage_index(ranks, 1:len), true)
end

"""
    namedtuple(lineage::Lineage; kwargs...)

Return a NamedTuple whose filednames is ranks (in the `CanonicalRanks`) of the `lineage`.
This function is useful for converting `Lineage` to `DataFrame`, for example.

# Arguments

* `fill_by_missing::Bool = false` - If `true`, fills missing instead of `UnclassifiedTaxon`.

# Examples

```jldoctest
julia> ranks = [:domain, :phylum, :class, :order, :family, :genus, :species];

julia> lineage = reformat(Lineage(Taxon(9606)), ranks);

julia> nt = namedtuple(lineage);

julia> nt.species
9606 [species] Homo sapiens

julia> incomplete = reformat(Lineage(Taxon(9443)), ranks);

julia> nt = namedtuple(incomplete; fill_by_missing=true);

julia> ismissing(nt.species)
true
```
"""
function namedtuple(l::Lineage; fill_by_missing::Bool=false)
    ranks = l.ranks
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

# Examples

```jldoctest
julia> isdescendant(Taxon(9606), Taxon(9605))
true

julia> isdescendant(Taxon(9606), Taxon(10239))
false
```
"""
AbstractTrees.isdescendant(descendant::Taxon, ancestor::Taxon) = ancestor in Lineage(descendant)

"""
    isancestor(ancestor::Taxon, descendant::Taxon)

Return `true` if the former taxon is an ancestor of the latter taxon.

# Examples

```jldoctest
julia> isancestor(Taxon(9605), Taxon(9606))
true

julia> isancestor(Taxon(10239), Taxon(9606))
false
```
"""
isancestor(ancestor::Taxon, descendant::Taxon) = AbstractTrees.isdescendant(descendant, ancestor)
