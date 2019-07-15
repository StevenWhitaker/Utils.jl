# TODO: FOR DEVELOPMENT ONLY ##################################################################
include("spacing.jl")
const SpacingTypes = Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}}

"""
    AbstractInterpolator

Abstract type for describing interpolators.
"""
abstract type AbstractInterpolator{T,S<:SpacingTypes,N} end
###############################################################################################

"""
    BSplineInterpolator(order, data[, spacing]) <: AbstractInterpolator

Create an interpolator that uses B-splines.

# Properties
- `data::Array`: Data used for interpolation
- `spacing::Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}} =
    Tuple([UnitSpacing(1, size(data, n)) for n = 1:ndims(data)])`: Positions or
    locations of the data points
"""
struct BSplineInterpolator{O,T<:Number,S<:SpacingTypes,N} <: AbstractInterpolator{T,S,N}
    # TODO: How does B-spline interpolation work with non-gridded data?
    data::Array{T,N}
    spacing::S

    BSplineInterpolator{O,T,S,N}(data::Array{T,N}, spacing::S) where {O,T<:Number,S<:SpacingTypes,N} = begin
        (S <: AbstractSpacing ? size(data) == size(spacing) : all([size(data, n) == size(spacing[n], 1) for n = 1:N])) ||
            throw(ArgumentError("size mismatch: each data point must have a position, and vice versa"))
        O isa Int || throw(ArgumentError("BSpline order must be an Int"))
        O >= 0 || throw(ArgumentError("BSpline order must be nonnegative"))
        new{O,T,typeof(spacing),N}(data, spacing)
    end
end
BSplineInterpolator(order::Int, data::Array{T,1}, spacing::S = UnitSpacing(1, length(data))) where {T,S<:AbstractSpacing} =
    BSplineInterpolator{order,T,S,1}(data, spacing)
BSplineInterpolator(order::Int, data::Array{T,N}, spacing::Union{<:AbstractNonGridSpacing,<:Tuple{Vararg{<:AbstractGridSpacing,N}}} =
    Tuple([UnitSpacing(1, size(data, n)) for n = 1:N])) where {T,N} =
    BSplineInterpolator{order,T,typeof(spacing),N}(data, spacing)
BSplineInterpolator(order::Int, data::AbstractArray, spacing::SpacingTypes) =
    BSplineInterpolator(order, convert(Array, data), spacing)
BSplineInterpolator(order::Int, data::AbstractArray) =
    BSplineInterpolator(order, convert(Array, data))
# TODO: Add constructor and conversion from ranges

Base.show(io::IO, interp::BSplineInterpolator{O,T,S,N}) where {O,T,S,N} =
    print(io, "BSplineInterpolator{$O,$T,$S,$N}:\n  order = $O\n  data = ", interp.data, "\n  spacing = ", interp.spacing)
