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
struct UnitSpacing{T<:Number} <: AbstractConstantSpacing{T}
    first::T
    last::T

    UnitSpacing{T}(first::T, last::T) where {T<:Number} = begin
        first <= last ||
            throw(ArgumentError("must have first <= last"))
        (last - first) % 1 == 0 ||
            throw(ArgumentError("difference between last and first must be an integer"))
        new{T}(first, last)
    end
end
UnitSpacing(first::T, last::T) where {T<:Number} = UnitSpacing{T}(first, last)
UnitSpacing(first::Number, last::Number) = UnitSpacing(promote(first, last)...)
# TODO: Add constructor and conversion from UnitRange

Base.size(pos::UnitSpacing) = (Int(pos.last - pos.first) + 1,)
Base.getindex(pos::UnitSpacing, i::Int) = begin
    # It might be useful to be able to access outside of the array for extrapolation
    # 1 <= i <= length(pos) || throw(BoundsError(pos, i))
    pos.first + i - 1
end
Base.getindex(pos::UnitSpacing, I::AbstractArray{Int,1}) =
    [getindex(pos, I[i]) for i in eachindex(I)]
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
struct ConstantSpacing{T<:Number,S<:Number} <: AbstractConstantSpacing{T}
    first::T
    last::T
    step::S

    ConstantSpacing{T,S}(first::T, last::T, step::S) where {T<:Number,S<:Number} = begin
        first <= last ||
            throw(ArgumentError("must have first <= last"))
        (last - first) % step == 0 ||
            throw(ArgumentError("difference between last and first must be a multiple of step"))
        new{T,S}(first, last, step)
    end
end
ConstantSpacing(first::T, last::T, step::S) where{T<:Number,S<:Number} =
    ConstantSpacing{T,S}(first, last, step)
ConstantSpacing(first::Number, last::Number, step::Number) =
    ConstantSpacing(promote(first, last)..., step)
ConstantSpacing(first::Number, last::Number; nsteps::Integer) =
    ConstantSpacing(promote(first, last)..., (last - first) / nsteps)
# TODO: Add contructor and conversion from LinRange and Range (AbstractRange) objects

Base.size(pos::ConstantSpacing) = (Int((pos.last - pos.first) / pos.step) + 1,)
Base.getindex(pos::ConstantSpacing, i::Int) = begin
    # 1 <= i <= length(pos) || throw(BoundsError(pos, i))
    pos.first + (i - 1) * pos.step
end
Base.getindex(pos::ConstantSpacing, I::AbstractArray{Int,1}) =
    [getindex(pos, I[i]) for i in eachindex(I)]
Base.IndexStyle(::Type{<:ConstantSpacing}) = IndexLinear()
Base.show(io::IO, pos::ConstantSpacing) =
    print(io, pos.first, ":", pos.step, ":", pos.last)
Base.show(io::IO, ::MIME"text/plain", pos::ConstantSpacing{T,S}) where {T,S} =
    print(io, "ConstantSpacing{$T,$S}: ", pos)

"""
    VariableSpacing(pos) <: AbstractGridSpacing

Spacing between data points is not constant.

# Properties
- `pos::Array{<:Number,1}`: Sorted vector containing positions of data points
"""
struct VariableSpacing{T<:Number} <: AbstractGridSpacing{T}
    pos::Array{T,1}

    VariableSpacing{T}(pos::Array{T,1}) where {T<:Number} = begin
        issorted(pos) || throw(ArgumentError("position vector must be sorted"))
        new{T}(pos)
    end
end
VariableSpacing(pos::Array{T,1}) where {T<:Number} = VariableSpacing{T}(pos)
VariableSpacing(pos::AbstractArray{<:Number,1}) =
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
