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
