"""
    AbstractSpacing <: AbstractArray

Abstract type for describing the spacing of data points.
"""
abstract type AbstractSpacing{T,N} <: AbstractArray{T,N} end

"""
    AbstractGridSpacing <: AbstractSpacing

Abstract type for describing data points that lie on a grid.
"""
abstract type AbstractGridSpacing{T} <: AbstractSpacing{T,1} end

"""
    AbstractConstantSpacing <: AbstractGridSpacing

Abstract type for describing equally spaced data points.
"""
abstract type AbstractConstantSpacing{T} <: AbstractGridSpacing{T} end

"""
    UnitSpacing(first, last) <: AbstractConstantSpacing

Spacing between data points is constant and equal to one.

# Properties
- `first::Number`: Position of first data point
- `last::Number`: Position of last data point
"""
struct UnitSpacing{T} <: AbstractConstantSpacing{T}
    first::T
    last::T

    UnitSpacing{T}(first::T, last::T) where {T} = begin
        first <= last ||
            throw(ArgumentError("must have first <= last"))
        (last - first) % 1 == 0 ||
            throw(ArgumentError("difference between last and first must be an integer"))
        new{T}(first, last)
    end
end
UnitSpacing(first::T, last::T) where {T} = UnitSpacing{T}(first, last)
UnitSpacing(first, last) = UnitSpacing(promote(first, last)...)
# TODO: Add constructor and conversion from UnitRange

Base.size(pos::UnitSpacing) = (Int(pos.last - pos.first) + 1,)
Base.getindex(pos::UnitSpacing, i::Int) = begin
    # It might be useful to be able to access outside of the array for extrapolation
    # 1 <= i <= length(pos) || throw(BoundsError(pos, i))
    pos.first + i - 1
end
Base.getindex(pos::UnitSpacing, I::AbstractArray{Int,1}) =
    [getindex(pos, i) for i in I]
Base.IndexStyle(::Type{<:UnitSpacing}) = IndexLinear()
Base.show(io::IO, pos::UnitSpacing) = print(io, pos.first, ":", pos.last)
Base.show(io::IO, ::MIME"text/plain", pos::UnitSpacing{T}) where {T} =
    print(io, "UnitSpacing{$T}: ", pos)

# Not sure adding them makes sense, but I'll leave the code here just in case
# Base.:+(pos1::UnitSpacing, pos2::UnitSpacing) = begin
#     length(pos1) == length(pos2) ||
#         throw(ArgumentError("lengths of inputs must be equal"))
#     ConstantSpacing(pos1.first + pos2.first, pos1.last + pos2.last, 2)
# end

"""
    ConstantSpacing(first, last, step) <: AbstractConstantSpacing

Spacing between data points is constant.

# Properties
- `first::Number`: Position of first data point
- `last::Number`: Position of last data point
- `step::Number`: Distance between adjacent data points
"""
struct ConstantSpacing{T} <: AbstractConstantSpacing{T}
    first::T
    last::T
    step::T

    ConstantSpacing{T}(first::T, last::T, step::T) where {T} = begin
        first <= last ||
            throw(ArgumentError("must have first <= last"))
        length = (last - first) / step
        first + step * length == last ||
        # (last - first) % step == 0 || # % not defined for Base.TwicePrecision{Float64}
            throw(ArgumentError("difference between last and first must be a multiple of step"))
        new{T}(first, last, step)
    end
end
ConstantSpacing(first::T, last::T, step::T) where {T} =
    ConstantSpacing{T}(first, last, step)
ConstantSpacing(first::Float64, last::Float64, step::Float64) = begin
    # Without Base.TwicePrecision one experiences round-off errors that make
    # pos[end] != pos.last
    # Still, though, 3 * 0.1 != 0.3 == prevfloat(3 * 0.1), even with TwicePrecision...
    T = Base.TwicePrecision{Float64}
    ConstantSpacing(T(first), T(last), T(step))
end
ConstantSpacing(first::T, last::T, step::T) where {T<:Union{Float16,Float32}} =
    ConstantSpacing(Float64(first), Float64(last), Float64(step))
ConstantSpacing(first, last, step) =
    ConstantSpacing(promote(first, last, step)...)
ConstantSpacing(first, last; nsteps::Integer) =
    ConstantSpacing(first, last, (last - first) / nsteps)
# TODO: Add contructor and conversion from LinRange and Range (AbstractRange) objects

Base.size(pos::ConstantSpacing) = (Int((pos.last - pos.first) / pos.step) + 1,)
Base.getindex(pos::ConstantSpacing, i::Int) = begin
    # 1 <= i <= length(pos) || throw(BoundsError(pos, i))
    pos.first + (i - 1) * pos.step
end
Base.getindex(pos::ConstantSpacing{Base.TwicePrecision{Float64}}, i::Int) =
    Float64(pos.first + (i - 1) * pos.step)
Base.getindex(pos::ConstantSpacing, I::AbstractArray{Int,1}) =
    [getindex(pos, i) for i in I]
Base.IndexStyle(::Type{<:ConstantSpacing}) = IndexLinear()
Base.eltype(::ConstantSpacing{Base.TwicePrecision{Float64}}) = Float64
Base.show(io::IO, pos::ConstantSpacing) =
    print(io, pos.first, ":", pos.step, ":", pos.last)
Base.show(io::IO, pos::ConstantSpacing{Base.TwicePrecision{Float64}}) =
    print(io::IO, Float64(pos.first), ":", Float64(pos.step), ":", Float64(pos.last))
Base.show(io::IO, ::MIME"text/plain", pos::ConstantSpacing{T}) where {T} =
    print(io, "ConstantSpacing{$T}: ", pos)
Base.show(io::IO, ::MIME"text/plain", pos::ConstantSpacing{Base.TwicePrecision{Float64}}) =
    print(io, "ConstantSpacing{Float64}: ", pos)

"""
    VariableSpacing(pos) <: AbstractGridSpacing

Spacing between data points is not constant.

# Properties
- `pos::Array{<:Number,1}`: Sorted vector containing positions of data points
"""
struct VariableSpacing{T} <: AbstractGridSpacing{T}
    pos::Array{T,1}

    VariableSpacing{T}(pos::Array{T,1}) where {T} = begin
        issorted(pos) || throw(ArgumentError("position vector must be sorted"))
        new{T}(pos)
    end
end
VariableSpacing(pos::Array{T,1}) where {T} = VariableSpacing{T}(pos)
VariableSpacing(pos::AbstractArray{<:Any,1}) =
    VariableSpacing(convert(Array, pos))

Base.size(pos::VariableSpacing) = size(pos.pos)
Base.getindex(pos::VariableSpacing, i::Int) = pos.pos[i]
Base.IndexStyle(::Type{<:VariableSpacing}) = IndexLinear()
Base.show(io::IO, pos::VariableSpacing{T}) where {T} =
    print(io, "VariableSpacing{$T}", pos.pos)

"""
    AbstractNonGridSpacing <: AbstractSpacing

Abstract type for describing data points that do not lie on a grid.
"""
abstract type AbstractNonGridSpacing{T,N} <: AbstractSpacing{T,N} end

const SpacingTypes = Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}}

"""
    AbstractInterpolator

Abstract type for describing interpolators.
"""
abstract type AbstractInterpolator{T,S<:SpacingTypes,N} end

struct NearestInterpolator{T<:Number,S<:SpacingTypes,N} <: AbstractInterpolator{T,S,N}
    data::Array{T,N}
    pos::S

    NearestInterpolator{T,S,N}(data::Array{T,N}, pos::S) where {T<:Number,S<:SpacingTypes,N} = begin
        # size(data) == ??? # TODO: Make sure sizes match
        new{T,typeof(pos),N}(data, pos)
    end
end
NearestInterpolator(data::Array{T,1}, pos::AbstractSpacing) where {T} =
    NearestInterpolator{T,typeof(pos),1}(data, pos)
NearestInterpolator(data::Array{T,N}, pos::Union{<:AbstractNonGridSpacing,<:Tuple{Vararg{<:AbstractGridSpacing,N}}}) where {T,N} =
    NearestInterpolator{T,typeof(pos),N}(data, pos)
NearestInterpolator(data::AbstractArray, pos::SpacingTypes) =
    NearestInterpolator(convert(Array, data), pos)

# """
#     NearestInterpolator([pos, ]val) <: AbstractInterpolator
#
# Create a nearest-neighbor interpolator.
#
# # Properties
# - `pos::AbstractArray{<:AbstractArray{<:Any,1},1} = [1:N[i] for i = 1:D]`:
#     Positions of corresponding values, i.e., the position of `val[i...]` is
#     given by `(pos[1][i[1]], pos[2][i[2]], ...)`; the default is the
#     traditional 1-based indexing, i.e., `pos[i...] == i`
# - `val::Array`: Values from which to interpolate
# """
# struct NearestInterpolator{T,P<:AbstractArray{<:AbstractArray{<:Any,1},1},N} <: AbstractInterpolator
#     val::Array{T,N}
#     pos::P
#
#     NearestInterpolator(val::Array{T,N}, pos::P) where {T,P<:AbstractArray{<:AbstractArray{<:Any,1},1},N} = begin
#         length(pos) == N ||
#             throw(ArgumentError("length(pos) must be N"))
#         size(val) == Tuple([length(pos[i]) for i = 1:N]) ||
#             throw(ArgumentError("length of each element of pos must equal the size of the corresponding dimension of val"))
#         new{T,P,N}(val, pos)
#     end
#
#     NearestInterpolator(val::Array{T,N}) where {T,N} = begin
#         pos = [1:size(val, n) for n = 1:N]
#         new{T,typeof(pos),N}(val, pos)
#     end
# end
#
# """
#     NearestInterpolator(pos)
#
# Find the nearest data point to the given position.
# """
# function (interp::NearestInterpolator{T,P,N})(pos::Vararg{Any,N}) where {T,P,N}
#
#     interp.val[[argmin(abs.(interp.pos[n] .- pos[n])) for n = 1:N]...]
#
# end
