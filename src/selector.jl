struct All end

struct Cols{T<:Tuple}
    cols::T
end

Cols(cols...) = Cols(cols)

struct Between{T,U}
    first::T
    last::U
end

Between(first::AbstractString, last) = Between(Symbol(first), last)
Between(first, last::AbstractString) = Between(first, Symbol(last))
Between(first::AbstractString, last::AbstractString) = Between(Symbol(first), Symbol(last))

struct From{T <: Union{Int, Symbol}}
    first::T
end

From(x::AbstractString) = From(Symbol(x))

struct Until{T <: Union{Int, Symbol}}
    last::T
end

Until(x::AbstractString) = Until(Symbol(x))
