module Utils

using Plots: plot, heatmap, backend, plotly, Gray
using ImageSegmentation: seeded_region_growing

include("plots.jl")

export myplot, iplot, getroi, plotroi, segment

end
