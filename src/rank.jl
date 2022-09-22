using InteractiveUtils

abstract type Rank end
abstract type CanonicalRank <: Rank end

const CanonicalRanks = [:species, :genus, :family, :order, :class, :phylum, :kingdom, :superkingdom]

for (i, rank) in enumerate(CanonicalRanks)
    @eval begin
        struct $rank <: CanonicalRank end
        rank(::$rank) = Symbol($rank)
        Base.Integer(::$rank) = $i
    end
end

function Rank(s::Symbol)
    if s in CanonicalRanks
        return @eval $s()
    else
        return UnCanonicalRank(s)
    end
end

Base.Integer(T::Type{<:CanonicalRank}) = Integer(T())
Base.isless(x1::CanonicalRank, x2::CanonicalRank) = isless(Integer(x1), Integer(x2))
Base.isless(x1::Type{<:CanonicalRank}, x2::Type{<:CanonicalRank}) = isless(x1(), x2())

const CanonicalRankSet = subtypes(CanonicalRank)

struct UnCanonicalRank <: Rank
    rank::Symbol
end

rank(ucr::UnCanonicalRank) = ucr.rank
Base.show(io::IO, r::Rank) = print(io, String(rank(r)))
