"""
    All()

Select the full `Lineage`.

# Examples

```jldoctest
julia> lineage = Lineage(Taxon(9606));

julia> lineage[All()] === lineage
true
```
"""
struct All end

"""
    Cols(cols...)

Select lineage items by multiple positions or canonical ranks.
Items must be requested from higher to lower rank.

# Examples

```jldoctest
julia> lineage = Lineage(Taxon(9606));

julia> taxid.(lineage[Cols(:class, :species)])
2-element Vector{Int64}:
 40674
  9606
```
"""
struct Cols{T<:Tuple}
    cols::T
end

Cols(cols...) = Cols(cols)

"""
    Between(first, last)

Select lineage items from `first` through `last`, where each boundary can be a position or canonical rank.
String rank names are converted to `Symbol`s.

# Examples

```jldoctest
julia> lineage = Lineage(Taxon(9606));

julia> taxid.(lineage[Between(:order, :family)])
6-element Vector{Int64}:
   9443
 376913
 314293
   9526
 314295
   9604
```
"""
struct Between{T,U}
    first::T
    last::U
end

Between(first::AbstractString, last) = Between(Symbol(first), last)
Between(first, last::AbstractString) = Between(first, Symbol(last))
Between(first::AbstractString, last::AbstractString) = Between(Symbol(first), Symbol(last))

"""
    From(first)

Select lineage items from `first` through the end, where `first` can be a position or canonical rank.
String rank names are converted to `Symbol`s.

# Examples

```jldoctest
julia> lineage = Lineage(Taxon(9606));

julia> first(taxid.(lineage[From(:family)])), last(taxid.(lineage[From(:family)]))
(9604, 9606)
```
"""
struct From{T <: Union{Int, Symbol}}
    first::T
end

From(x::AbstractString) = From(Symbol(x))

"""
    Until(last)

Select lineage items from the beginning through `last`, where `last` can be a position or canonical rank.
String rank names are converted to `Symbol`s.

# Examples

```jldoctest
julia> lineage = Lineage(Taxon(9606));

julia> last(taxid.(lineage[Until(:kingdom)]))
33208
```
"""
struct Until{T <: Union{Int, Symbol}}
    last::T
end

Until(x::AbstractString) = Until(Symbol(x))
