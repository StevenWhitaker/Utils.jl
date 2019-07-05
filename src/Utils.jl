module Utils

using Plots: plot, plot!, scatter, scatter!, heatmap, histogram, histogram2d,
             backend, plotly, Gray, AbstractBackend
using ImageSegmentation: seeded_region_growing

include("plots.jl")
include("arrays.jl")

export myplot, myplot!, myscatter, myscatter!, myhist, iplot, getroi, plotroi,
       segment
export myfill, embed, @squeeze

end
