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

Base.size(spacing::UnitSpacing) = (Int(spacing.last - spacing.first) + 1,)
Base.getindex(spacing::UnitSpacing, i::Int) = begin
    # It might be useful to be able to access outside of the array for extrapolation
    # 1 <= i <= length(spacing) || throw(BoundsError(spacing, i))
    spacing.first + i - 1
end
Base.getindex(spacing::UnitSpacing, I::AbstractArray{Int,1}) =
    [getindex(spacing, i) for i in I]
Base.IndexStyle(::Type{<:UnitSpacing}) = IndexLinear()
Base.show(io::IO, spacing::UnitSpacing{T}) where {T} =
    print(io, "UnitSpacing{$T}: ", spacing.first, ":", spacing.last)

# Not sure adding them makes sense, but I'll leave the code here just in case
# Base.:+(spacing1::UnitSpacing, spacing2::UnitSpacing) = begin
#     length(spacing1) == length(spacing2) ||
#         throw(ArgumentError("lengths of inputs must be equal"))
#     ConstantSpacing(spacing1.first + spacing2.first, spacing1.last + spacing2.last, 2)
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
    # spacing[end] != spacing.last
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

Base.size(spacing::ConstantSpacing) =
    (Int((spacing.last - spacing.first) / spacing.step) + 1,)
Base.getindex(spacing::ConstantSpacing, i::Int) = begin
    # 1 <= i <= length(spacing) || throw(BoundsError(spacing, i))
    spacing.first + (i - 1) * spacing.step
end
Base.getindex(spacing::ConstantSpacing{Base.TwicePrecision{Float64}}, i::Int) =
    Float64(spacing.first + (i - 1) * spacing.step)
Base.getindex(spacing::ConstantSpacing, I::AbstractArray{Int,1}) =
    [getindex(spacing, i) for i in I]
Base.IndexStyle(::Type{<:ConstantSpacing}) = IndexLinear()
Base.eltype(::ConstantSpacing{Base.TwicePrecision{Float64}}) = Float64
Base.show(io::IO, spacing::ConstantSpacing{T}) where {T} =
    print(io, "ConstantSpacing{$T}: ", spacing.first, ":", spacing.step, ":", spacing.last)
Base.show(io::IO, spacing::ConstantSpacing{Base.TwicePrecision{Float64}}) =
    print(io::IO, "ConstantSpacing{Float64}: ", Float64(spacing.first), ":", Float64(spacing.step), ":", Float64(spacing.last))

"""
    VariableSpacing(spacing) <: AbstractGridSpacing

Spacing between data points is not constant.

# Properties
- `spacing::Array{<:Number,1}`: Sorted vector containing positions of data points
"""
struct VariableSpacing{T} <: AbstractGridSpacing{T}
    spacing::Array{T,1}

    VariableSpacing{T}(spacing::Array{T,1}) where {T} = begin
        issorted(spacing) ||
            throw(ArgumentError("spacing vector must be sorted"))
        new{T}(spacing)
    end
end
VariableSpacing(spacing::Array{T,1}) where {T} = VariableSpacing{T}(spacing)
VariableSpacing(spacing::AbstractArray{<:Any,1}) =
    VariableSpacing(convert(Array, spacing))

Base.size(spacing::VariableSpacing) = size(spacing.spacing)
Base.getindex(spacing::VariableSpacing, i::Int) = spacing.spacing[i]
Base.IndexStyle(::Type{<:VariableSpacing}) = IndexLinear()
Base.show(io::IO, spacing::VariableSpacing{T}) where {T} =
    print(io, "VariableSpacing{$T}", spacing.spacing)

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

"""
    NearestInterpolator(data[, spacing]) <: AbstractInterpolator

Create a nearest-neighbor interpolator.

# Properties
- `data::Array`: Data used for interpolation
- `spacing::Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}} =
    Tuple([UnitSpacing(1, size(data, n)) for n = 1:ndims(data)])`: Positions or
    locations of the data points
"""
struct NearestInterpolator{T<:Number,S<:SpacingTypes,N} <: AbstractInterpolator{T,S,N}
    data::Array{T,N}
    spacing::S

    NearestInterpolator{T,S,N}(data::Array{T,N}, spacing::S) where {T<:Number,S<:SpacingTypes,N} = begin
        (S <: AbstractSpacing ? size(data) == size(spacing) : all([size(data, n) == size(spacing[n], 1) for n = 1:N])) ||
            throw(ArgumentError("size mismatch: each data point must have a position, and vice versa"))
        new{T,typeof(spacing),N}(data, spacing)
    end
end
NearestInterpolator(data::Array{T,1}, spacing::S = UnitSpacing(1, length(data))) where {T,S<:AbstractSpacing} =
    NearestInterpolator{T,S,1}(data, spacing)
NearestInterpolator(data::Array{T,N}, spacing::Union{<:AbstractNonGridSpacing,<:Tuple{Vararg{<:AbstractGridSpacing,N}}} =
    Tuple([UnitSpacing(1, size(data, n)) for n = 1:N])) where {T,N} =
    NearestInterpolator{T,typeof(spacing),N}(data, spacing)
NearestInterpolator(data::AbstractArray, spacing::SpacingTypes) =
    NearestInterpolator(convert(Array, data), spacing)
NearestInterpolator(data::AbstractArray) =
    NearestInterpolator(convert(Array, data))

Base.show(io::IO, interp::NearestInterpolator{T,S,N}) where {T,S,N} =
    print(io, "NearestInterpolator{$T,$S,$N}:\n  data = ", interp.data, "\n  spacing = ", interp.spacing)

"""
    NearestInterpolator(pos)

Find the nearest data point to the given position.
"""
function (interp::NearestInterpolator{T,S,N})(pos::Vararg{Any,N}) where {T,S,N}

    index = findclosest(interp.spacing, pos...)
    return interp.data[index]

end

"""
    findclosest(spacing, pos[, num])

Find the index(es) of the `num` points closest to `pos`. Ties round up.

# Arguments
- `spacing::AbstractSpacing`: Spacing object
- `pos`: Position to find points close to
- `num::Integer = 1`: Find the closes `num` points
"""
function findclosest(spacing::AbstractGridSpacing, pos)

    # The first two branches implement extrapolation
    if pos <= spacing[1]
        return 1
    elseif pos >= spacing[end]
        return length(spacing)
    else
        return _findclosest(spacing, pos)
    end

end

function findclosest(spacing::AbstractGridSpacing, pos::AbstractArray)

    return [findclosest(spacing, p) for p in pos]

end

function _findclosest(spacing::UnitSpacing, pos)

    return round(Int, pos - spacing.first + 1, RoundNearestTiesUp)

end

# I need this function because in this case (pos - spacing.first) is an Integer,
# and round(...) does not accept a rounding mode when rounding Integers
function _findclosest(spacing::UnitSpacing{<:Integer}, pos::Integer)

    return pos - spacing.first + 1

end

function _findclosest(spacing::ConstantSpacing, pos)

    return round(Int, (pos - spacing.first) / spacing.step + 1, RoundNearestTiesUp)

end

function _findclosest(spacing::VariableSpacing, pos)

    index = searchsortedlast(spacing, pos)
    diffbelow = pos - spacing[index]
    diffabove = spacing[index+1] - pos
    return diffbelow < diffabove ? index : index + 1

end
