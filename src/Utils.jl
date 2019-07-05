module Utils

using Plots: plot, plot!, scatter, scatter!, heatmap, backend, plotly, Gray,
             AbstractBackend
using ImageSegmentation: seeded_region_growing

include("plots.jl")
include("arrays.jl")

export myplot, myplot!, myscatter, myscatter!, iplot, getroi, plotroi, segment
export myfill, embed, @squeeze

end
