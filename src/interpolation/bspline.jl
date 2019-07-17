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
    Order

Singleton types for specifying the BSpline order.
"""
struct Order{O} end

"""
    BoundaryCondition

Supertype for types specifying the boundary conditions used in prefiltering.
"""
abstract type BoundaryCondition end
struct ZeroBC <: BoundaryCondition end
struct ConstantBC <: BoundaryCondition end
struct PeriodicBC{K} <: BoundaryCondition end # K specifies number of terms in sum on page 8.45
struct MirrorBC{K} <: BoundaryCondition end

"""
    BSplineInterpolator(order, data[, spacing][, boundarycondition]) <: AbstractInterpolator

Create an interpolator that uses B-splines.

# Properties
- `data::Array`: Data used for interpolation
- `spacing::Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}} =
    Tuple([UnitSpacing(1, size(data, n)) for n = 1:ndims(data)])`: Positions or
    locations of the data points
- `prefiltdata::Array`: Prefiltered data
"""
struct BSplineInterpolator{O<:Order,T<:Number,S<:SpacingTypes,B<:BoundaryCondition,N} <: AbstractInterpolator{T,S,N}
    # TODO: How does B-spline interpolation work with non-gridded data?
    data::Array{T,N}
    spacing::S
    prefiltdata::Array{Float64,N}

    BSplineInterpolator{O,T,S,B,N}(data::Array{T,N}, spacing::S) where {O<:Order,T<:Number,S<:SpacingTypes,B<:BoundaryCondition,N} = begin
        (S <: AbstractSpacing ? size(data) == size(spacing) : all([size(data, n) == size(spacing[n], 1) for n = 1:N])) ||
            throw(ArgumentError("size mismatch: each data point must have a position, and vice versa"))
        prefiltdata = prefilter(O(), data, B())
        new{O,T,typeof(spacing),B,N}(data, spacing, prefiltdata)
    end
end
BSplineInterpolator(order::Int, data::Array{T,1}, spacing::S, bc::B) where {T,S<:AbstractSpacing,B<:BoundaryCondition} =
    BSplineInterpolator{Order{order},T,S,B,1}(data, spacing)
BSplineInterpolator(order::Int, data::Array{T,N}, spacing::Union{<:AbstractNonGridSpacing,<:Tuple{Vararg{<:AbstractGridSpacing,N}}}, bc::B) where {T,S<:AbstractSpacing,B<:BoundaryCondition,N} =
    BSplineInterpolator{Order{order},T,typeof(spacing),B,N}(data, spacing)
BSplineInterpolator(order::Int, data::Array{T,1}, spacing::S) where {T,S<:AbstractSpacing} =
    BSplineInterpolator{Order{order},T,S,ZeroBC,1}(data, spacing)
BSplineInterpolator(order::Int, data::Array{T,N}, spacing::Union{<:AbstractNonGridSpacing,<:Tuple{Vararg{<:AbstractGridSpacing,N}}}) where {T,S<:AbstractSpacing,N} =
    BSplineInterpolator{Order{order},T,typeof(spacing),ZeroBC,N}(data, spacing)
BSplineInterpolator(order::Int, data::Array{T,1}, bc::B = ZeroBC()) where {T,B<:BoundaryCondition} = begin
    spacing = UnitSpacing(1, length(data))
    BSplineInterpolator{Order{order},T,typeof(spacing),B,1}(data, spacing)
end
BSplineInterpolator(order::Int, data::Array{T,N}, bc::B = ZeroBC()) where {T,B<:BoundaryCondition,N} = begin
    spacing = Tuple([UnitSpacing(1, size(data, n)) for n = 1:N])
    BSplineInterpolator{Order{order},T,typeof(spacing),B,N}(data, spacing)
end
BSplineInterpolator(order::Int, data::AbstractArray, args...) =
    BSplineInterpolator(order, convert(Array, data), args...)

QuadraticBSplineInterpolator(args...) = BSplineInterpolator(2, args...)
CubicBSplineInterpolator(args...) = BSplineInterpolator(3, args...)

Base.show(io::IO, interp::BSplineInterpolator{O,T,S,B,N}) where {O,T,S,B,N} =
    print(io, "BSplineInterpolator{$O,$T,$S,$B,$N}:\n  data = ", interp.data, "\n  spacing = ", interp.spacing)

function (interp::BSplineInterpolator{O,T,S,N})(pos::Vararg{<:Any,N}) where {O,T,S,N}



end

function prefilter(order::Order, data::AbstractArray{<:Number,1}, bc::BoundaryCondition)

    N = length(data)
    y = zeros(N)
    c = zeros(N)
    (ainv, p) = prefilterconst(order)

    y[1] = inity(bc, ainv, p, data)
    for n = 2:N
        y[n] = ainv * data[n] + p * y[n-1]
    end

    c[N] = initc(bc, p, y)
    for n = N-1:-1:1
        c[n] = p * (c[n+1] - y[n])
    end

    return c

end

@inline kernelcoeff(::Order{2}) = (6//8, 1//8)
@inline kernelcoeff(::Order{3}) = (4//6, 1//6)

@inline prefilterconst(::Order{2}) = (8, -0.1715728752538097)
@inline prefilterconst(::Order{3}) = (6, -0.2679491924311228)

getp(b0, b1) = -b0 / 2b1 + sqrt((b0 / 2b1)^2 - 1)

function inity(::ZeroBC, ainv, p, data)

    return ainv * data[1]

end

function inity(::ConstantBC, ainv, p, data)

    return ainv * data[1] / (1 - p)

end

# It looks like assuming periodicity of the signal also makes y periodic
function inity(::PeriodicBC{K}, ainv, p, data) where {K}

    N = length(data)
    k = 1:min(K, N)
    return ainv * (data[1] + sum(p.^k .* data[(N+1) .- k]))

end

function inity(::MirrorBC{K}, ainv, p, data) where {K}

    k = 1:min(K, length(data) - 1)
    return ainv * (data[1] + sum(p.^k .* data[k .+ 1]))

end

# I will assume for now that the boundary conditions apply to y and not to data
# TODO: Check this
function initc(::ZeroBC, p, y)

    return -p * y[end]

end

function initc(::ConstantBC, p, y)

    return -y[end] / (1 - p)

end

function initc(::PeriodicBC{K}, p, y) where {K}

    k = 1:min(K, length(y))
    return -p * (y[end] + sum(p.^k .* y[k]))

end

function initc(::MirrorBC{K}, p, y) where {K}

    N = length(y)
    k = 1:min(K + 1, N)
    return -sum(p.^k .* y[(N+1) .- k])

end
