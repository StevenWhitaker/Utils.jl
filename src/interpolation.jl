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
abstract type AbstractConstantSpacing <: AbstractGridSpacing end

"""
    UnitSpacing(first, last) <: AbstractConstantSpacing

Spacing between data points is constant and equal to one.

# Properties
- `first::Number`: Position of first data point
- `last::Number`: Position of last data point
"""
struct UnitSpacing{T<:Number} <: AbstractConstantSpacing
    first::T
    last::T

    UnitSpacing(first::T, last::T) where {T<:Number} = begin
        first <= last || throw(ArgumentError("must have first <= last"))
        (last - first) % 1 == 0 || throw(ArgumentError("difference between last and first must be an integer"))
        new{T}(first, last)
    end
end
# TODO: Add constructor and conversion from UnitRange

"""
    ConstantSpacing(first, last, step) <: AbstractConstantSpacing

Spacing between data points is constant.

# Properties
- `first::Number`: Position of first data point
- `last::Number`: Position of last data point
- `step::Number`: Distance between adjacent data points
"""
struct ConstantSpacing{T<:Number,S<:Number} <: AbstractConstantSpacing
    first::T
    last::T
    step::S

    ConstantSpacing(first::T, last::T, step::S) where {T<:Number,S<:Number} = begin
        first <= last || throw(ArgumentError("must have first <= last"))
        (last - first) % step == 0 || throw(ArgumentError("difference between last and first must be a multiple of step"))
        new{T,S}(first, last, step)
    end
end

ConstantSpacing(first::Number, last::Number; nsteps::Integer) =
    ConstantSpacing(promote(first, last)..., (last - first) / nsteps)
# TODO: Add contructor and conversion from LinRange and Range (AbstractRange) objects

"""
    AbstractInterpolator

Abstract type for describing interpolators.
"""
abstract type AbstractInterpolator end

"""
    NearestInterpolator([pos, ]val) <: AbstractInterpolator

Create a nearest-neighbor interpolator.

# Properties
- `pos::AbstractArray{<:AbstractArray{<:Any,1},1} = [1:N[i] for i = 1:D]`:
    Positions of corresponding values, i.e., the position of `val[i...]` is
    given by `(pos[1][i[1]], pos[2][i[2]], ...)`; the default is the
    traditional 1-based indexing, i.e., `pos[i...] == i`
- `val::Array`: Values from which to interpolate
"""
struct NearestInterpolator{T,P<:AbstractArray{<:AbstractArray{<:Any,1},1},N} <: AbstractInterpolator
    val::Array{T,N}
    pos::P

    NearestInterpolator(val::Array{T,N}, pos::P) where {T,P<:AbstractArray{<:AbstractArray{<:Any,1},1},N} = begin
        length(pos) == N ||
            throw(ArgumentError("length(pos) must be N"))
        size(val) == Tuple([length(pos[i]) for i = 1:N]) ||
            throw(ArgumentError("length of each element of pos must equal the size of the corresponding dimension of val"))
        new{T,P,N}(val, pos)
    end

    NearestInterpolator(val::Array{T,N}) where {T,N} = begin
        pos = [1:size(val, n) for n = 1:N]
        new{T,typeof(pos),N}(val, pos)
    end
end

"""
    NearestInterpolator(pos)

Find the nearest data point to the given position.
"""
function (interp::NearestInterpolator{T,P,N})(pos::Vararg{Any,N}) where {T,P,N}

    interp.val[[argmin(abs.(interp.pos[n] .- pos[n])) for n = 1:N]...]

end
