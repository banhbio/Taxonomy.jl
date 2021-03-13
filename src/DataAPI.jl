struct From{T <: Union{Int, Symbol}}
    first::T
end

From(x::AbstractString) = From(Symbol(x))

struct Until{T <: Union{Int, Symbol}}
    last::T
end

Until(x::AbstractString) = Until(Symbol(x))