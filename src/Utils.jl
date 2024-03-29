module Utils

using Plots
using ImageSegmentation
using LinearAlgebra
using Random

include("plots.jl")
include("arrays.jl")
include("optimization.jl")
include("distributions.jl")
include("timing.jl")
include("interpolation/Interpolation.jl")
using .Interpolation

export myplot, myplot!, myscatter, myscatter!, myhist, iplot, getroi, plotroi,
       segment, savefig
export myfill, embed, @squeeze
export gd, gpm, lsgd, nnlsgd
export LogUniform, Delta
export @mytime
export UnitSpacing, ConstantSpacing, VariableSpacing
export NearestInterpolator, LinearInterpolator

end
