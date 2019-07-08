module Utils

using Plots
using ImageSegmentation
using LinearAlgebra

include("plots.jl")
include("arrays.jl")
include("optimization.jl")

export myplot, myplot!, myscatter, myscatter!, myhist, iplot, getroi, plotroi,
       segment
export myfill, embed, @squeeze
export gd, gpm, lsgd, nnlsgd

end
