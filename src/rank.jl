using InteractiveUtils

abstract type Rank end
abstract type CanonicalRank <: Rank end

const CanonicalRankCodes = Pair{Symbol, Int}[
    :domain => 9,
    :superkingdom => 9,
    :realm => 9,
    :kingdom => 8,
    :phylum => 7,
    :class => 6,
    :order => 5,
    :family => 4,
    :genus => 3,
    :species => 2,
    :subspecies => 1,
    :strain => 1,
]

const CanonicalRanks = first.(CanonicalRankCodes)

for (rank_name, rank_code) in CanonicalRankCodes
    @eval begin
        struct $rank_name <: CanonicalRank end
        rank(::$rank_name) = Symbol($rank_name)
        Base.Integer(::$rank_name) = $rank_code
    end
end

Base.Integer(T::Type{<:CanonicalRank}) = Integer(T())

"""
    Rank(sym::Symbol)
Return `CanonicalRank(sym)` if sym is in `CanonicalRanks`. Return `UnCanonicalRank(sym)` if not.
`CanonicalRank(sym)` can be used for `isless` comparison.
`:domain`, `:superkingdom`, and `:realm` are treated as the same top-rank
level.

# Examples

```jldoctest
julia> Rank(:species) isa Taxonomy.CanonicalRank
true

julia> Rank(:clade) isa Taxonomy.UnCanonicalRank
true
```
"""
Rank

function gen_rank_codes()
    codes = map(CanonicalRanks) do r
        compare = Meta.parse("s == :$r")
        re = :(return $r())
        Expr(:if, compare, re)
    end
    return Expr(:block, codes...)
end

@eval function Rank(s::Symbol)
    # it will generate
    #=
    if s == :superkingdom
        return superkingdom()
    end
    ...
    if s == :strain
        return strain()
    end

    return UnCanonicalRank(s)
    =#
    $(gen_rank_codes())
    return UnCanonicalRank(s)
end

"""
    Rank(taxon::Taxon)
Return `CanonicalRank` made from `rank(taxon)` if `rank(taxon)` is in `CanonicalRanks`. Return `UnCanonicalRank(rank)` if not.
`CanonicalRank(taxon)` can be used for `isless` comparison.
`:domain`, `:superkingdom`, and `:realm` can all be handled as canonical
aliases for the same top-rank level.

# Examples

```jldoctest
julia> Rank(Taxon(9606)) isa Taxonomy.CanonicalRank
true
```
"""
Rank(taxon::AbstractTaxon) = rank(taxon) |> Rank

const CanonicalRankSet = subtypes(CanonicalRank)

struct UnCanonicalRank <: Rank
    rank::Symbol
end

rank(ucr::UnCanonicalRank) = ucr.rank
Base.show(io::IO, r::Rank) = print(io, String(rank(r)))

"""
    isless(taxon::AbstractTaxon, rank::CanonicalRank)

# Examples

```jldoctest
julia> Taxon(9606) < Rank(:genus)
true
```

Return `true` if the rank of the former `Taxon` is less than the later rank.
"""
Base.isless(x1::CanonicalRank, x2::CanonicalRank) = isless(Integer(x1), Integer(x2))

function Base.isless(x1::AbstractTaxon, x2::CanonicalRank)
    r = rank(x1) |> Rank
    r isa CanonicalRank && return isless(r, x2)
    p = AbstractTrees.parent(x1)
    while true
        isnothing(x1) && return false
        r = rank(x1) |> Rank
        r isa CanonicalRank && return isless(Integer(r)-1, Integer(x2))
        x1 = p
        p = AbstractTrees.parent(x1)
    end
end

Base.:<=(x1::AbstractTaxon, x2::CanonicalRank) = Rank(x1) == x2 ? true : x1 < x2
