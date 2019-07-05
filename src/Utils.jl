module Utils

using Plots
using ImageSegmentation

include("plots.jl")
include("arrays.jl")

export myplot, myplot!, myscatter, myscatter!, myhist, iplot, getroi, plotroi,
       segment
export myfill, embed, @squeeze

end
