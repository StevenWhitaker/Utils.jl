module Utils

using Plots: plot, heatmap, backend, plotly, Gray, AbstractBackend
using ImageSegmentation: seeded_region_growing

include("plots.jl")
include("arrays.jl")

export myplot, myplot!, iplot, getroi, plotroi, segment
export myfill, embed, @squeeze

end
