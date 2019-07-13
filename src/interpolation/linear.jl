# FOR DEVELOPMENT ONLY ########################################################################
include("spacing.jl")
const SpacingTypes = Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}}

"""
    AbstractInterpolator

Abstract type for describing interpolators.
"""
abstract type AbstractInterpolator{T,S<:SpacingTypes,N} end
###############################################################################################

"""
    LinearInterpolator(data[, spacing]) <: AbstractInterpolator

Create a linear interpolator.

# Properties
- `data::Array`: Data used for interpolation
- `spacing::Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}} =
    Tuple([UnitSpacing(1, size(data, n)) for n = 1:ndims(data)])`: Positions or
    locations of the data points
"""
struct LinearInterpolator{T<:Number,S<:SpacingTypes,N} <: AbstractInterpolator{T,S,N}
    # TODO: How does linear interpolation work with non-gridded data?
    data::Array{T,N}
    spacing::S

    LinearInterpolator{T,S,N}(data::Array{T,N}, spacing::S) where {T<:Number,S<:SpacingTypes,N} = begin
        (S <: AbstractSpacing ? size(data) == size(spacing) : all([size(data, n) == size(spacing[n], 1) for n = 1:N])) ||
            throw(ArgumentError("size mismatch: each data point must have a position, and vice versa"))
        new{T,typeof(spacing),N}(data, spacing)
    end
end
LinearInterpolator(data::Array{T,1}, spacing::S = UnitSpacing(1, length(data))) where {T,S<:AbstractSpacing} =
    LinearInterpolator{T,S,1}(data, spacing)
LinearInterpolator(data::Array{T,N}, spacing::Union{<:AbstractNonGridSpacing,<:Tuple{Vararg{<:AbstractGridSpacing,N}}} =
    Tuple([UnitSpacing(1, size(data, n)) for n = 1:N])) where {T,N} =
    LinearInterpolator{T,typeof(spacing),N}(data, spacing)
LinearInterpolator(data::AbstractArray, spacing::SpacingTypes) =
    LinearInterpolator(convert(Array, data), spacing)
LinearInterpolator(data::AbstractArray) =
    LinearInterpolator(convert(Array, data))
# TODO: Add constructor and conversion from ranges

Base.show(io::IO, interp::LinearInterpolator{T,S,N}) where {T,S,N} =
    print(io, "LinearInterpolator{$T,$S,$N}:\n  data = ", interp.data, "\n  spacing = ", interp.spacing)

"""
    LinearInterpolator(pos)

Linearly interpolate the data at the given position.
"""
function (interp::LinearInterpolator{T,S,N})(pos::Vararg{<:Any,N}) where {T,S,N}

    indexes = findneighbors(interp.spacing, pos...)
    datapos = getdatapos(interp.spacing, indexes)
    return linearinterpolation(interp.data[indexes], datapos, pos...)

end

function findneighbors(spacing::Tuple{Vararg{<:AbstractGridSpacing,N}}, pos::Vararg{<:Any,N}) where {N}

    return [findneighbors(spacing[n], pos[n]) for n = 1:N]

end

function findneighbors(spacing::UnitSpacing, pos)

    below = round(Int, pos - spacing.first, RoundNearestTiesUp)
    return [below, below + 1]

end

# I need this function because in this case (pos - spacing.first) is an Integer,
# and round(...) does not accept a rounding mode when rounding Integers
function findneighbors(spacing::UnitSpacing{<:Integer}, pos::Integer)

    below = pos - spacing.first
    return [below, below + 1]

end

function findneighbors(spacing::ConstantSpacing, pos)

    below = round(Int, (pos - spacing.first) / spacing.step, RoundNearestTiesUp)
    return [below, below + 1]

end

function findneighbors(spacing::VariableSpacing, pos)

    below = searchsortedlast(spacing, pos)
    return [below, below + 1]

end

function getdatapos(spacing::AbstractGridSpacing, indexes::AbstractArray{Int,1})

    return spacing[indexes]

end

function getdatapos(spacing::Tuple{Vararg{<:AbstractGridSpacing,N}}, indexes::AbstractArray{<:AbstractArray{Int,1},1})

    

end

function linearinterpolation(data::AbstractArray{T,N}, datapos::AbstractArray{S,N}, interppos::Vararg{<:Any,N}) where {T,S,N}

    dataposnew = similar(datapos, size(datapos)[2:end])
    interpposnew = interppos[2:end]
    # datanew = similar(data, size(data)[2:end])
    datanew = [linearinterpolation(data[:,i], datapos[:,i], interppos[1]) for i in eachindex(dataposnew)]
    return linearinterpolation(datanew, dataposnew, interpposnew...)

end

# Base case: 1D
function linearinterpolation(data::AbstractArray{T,1}, datapos::AbstractArray{S,1}, interppos) where {T,S}

    # Fit a line: y = (y1 - y0) / (x1 - x0) * (x - x0) + y0,
    # where [y0, y1] = data, [x0, x1] = datapos, x = interppos
    return (data[2] - data[1]) / (datapos[2] - datapos[1]) * (interppos - datapos[1]) + data[1]

end
