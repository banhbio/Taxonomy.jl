using InteractiveUtils

abstract type Rank end
abstract type CanonicalRank <: Rank end

const CanonicalRanks = [:superkingdom, :kingdom, :phylum, :class, :order, :family, :genus, :species, :subspecies, :strain]

for (i, rank) in enumerate(reverse(CanonicalRanks[1:end-2]))
    @eval begin
        struct $rank <: CanonicalRank end
        rank(::$rank) = Symbol($rank)
        Base.Integer(::$rank) = $i
    end
end

struct strain <: CanonicalRank end
rank(::strain) = :strain
Base.Integer(::strain) = 0

struct subspecies <: CanonicalRank end
rank(::subspecies) = :subspecies
Base.Integer(::subspecies) = 0

Base.Integer(T::Type{<:CanonicalRank}) = Integer(T())

"""
    Rank(sym::Symbol)
Return `CanonicalRank(sym)` if sym is in `CanonicalRanks`. Return `UnCanonicalRank(sym)` if not.
`CanonicalRank(sym)` can be used for `isless` comparison.
"""
function Rank(s::Symbol)
    if s in CanonicalRanks
        return @eval $s()
    else
        return UnCanonicalRank(s)
    end
end

"""
    Rank(taxon::Taxon)
Return `CanonicalRank` made from `rank(taxon)` if `rank(taxon)` is in `CanonicalRanks`. Return `UnCanonicalRank(rank)` if not.
`CanonicalRank(taxon)` can be used for `isless` comparison.
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

Example
```julia
julia> Taxon(9606 , db) < Rank(:genus)
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
