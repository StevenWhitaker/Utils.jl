module Utils

using Plots
using ImageSegmentation
using LinearAlgebra
using Random

include("plots.jl")
include("arrays.jl")
include("optimization.jl")
include("distributions.jl")
include("interpolation.jl")

export myplot, myplot!, myscatter, myscatter!, myhist, iplot, getroi, plotroi,
       segment
export myfill, embed, @squeeze
export gd, gpm, lsgd, nnlsgd
export LogUniform, Delta
export NearestInterpolator

end
