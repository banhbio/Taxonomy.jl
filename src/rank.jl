using InteractiveUtils

abstract type Rank end
abstract type CanonicalRank <: Rank end

const CanonicalRanks = [:strain, :subspecies, :species, :genus, :family, :order, :class, :phylum, :kingdom, :superkingdom]

for (i, rank) in enumerate(CanonicalRanks[3:end])
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

function Rank(s::Symbol)
    if s in CanonicalRanks
        return @eval $s()
    else
        return UnCanonicalRank(s)
    end
end

const CanonicalRankSet = subtypes(CanonicalRank)

struct UnCanonicalRank <: Rank
    rank::Symbol
end

rank(ucr::UnCanonicalRank) = ucr.rank
Base.show(io::IO, r::Rank) = print(io, String(rank(r)))

Base.isless(x1::CanonicalRank, x2::CanonicalRank) = isless(Integer(x1), Integer(x2))
Base.isless(x1::Type{<:CanonicalRank}, x2::Type{<:CanonicalRank}) = isless(x1(), x2())

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

Base.isless(x1::AbstractTaxon, x2::Type{<:CanonicalRank}) = isless(x1, x2())