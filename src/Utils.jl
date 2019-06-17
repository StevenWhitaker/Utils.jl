module Utils

using Plots: plot, heatmap, backend, plotly
using ImageSegmentation: seeded_region_growing, labels_map

include("plots.jl")

export myplot, iplot, getroi, plotroi, segment

end
