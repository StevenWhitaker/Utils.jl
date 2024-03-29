module Interpolation

include("spacing.jl")
const SpacingTypes = Union{<:AbstractSpacing,<:Tuple{Vararg{<:AbstractGridSpacing}}}

"""
    AbstractInterpolator

Abstract type for describing interpolators.
"""
abstract type AbstractInterpolator{T,S<:SpacingTypes,N} end

include("nearestneighbor.jl")
include("linear.jl")

export UnitSpacing, ConstantSpacing, VariableSpacing
export NearestInterpolator, LinearInterpolator

end
