"""
    myplot([idx,] x; kwargs...)

Create plot of `x` with preferred default values.

# Arguments
- `idx::AbstractArray = 1:length(x)`: Locations of data points
- `x::AbstractArray{<:Union{<:Number,<:AbstractArray{<:Number,1}},1}`: 1D data to plot
- `kwargs...`: Keyword arguments passed to `Plots.plot`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function myplot(x::AbstractArray{<:Real,1};
    idx = 1:length(x),
    label = "",
    linewidth = 2.5,
    kwargs...
)

    return plot(idx, x,
                label = label,
                linewidth = linewidth;
                kwargs...)

end

function myplot(x::AbstractArray{<:AbstractArray{<:Number,1},1};
    idx = [1:length(x[i]) for i = 1:length(x)],
    label = 1:length(x),
    kwargs...
)

    p = myplot(x[1],
               idx = idx[1],
               label = label[1];
               kwargs...)
    for i = 2:length(x)
        myplot!(p, x[2],
                idx = idx[min(i, length(idx))],
                label = label[min(i, length(label))];
                kwargs...)
    end
    return p

end

"""
    myplot!(p, [idx,] x; kwargs...)

Add the 1D data `x` to the given plot.
"""
function myplot!(p::Plots.Plot{<:AbstractBackend}, x::AbstractArray{<:Real,1};
    idx = 1:length(x),
    label = "",
    linewidth = 2.5,
    kwargs...
)

    plot!(p, idx, x,
          label = label,
          linewidth = linewidth;
          kwargs...)

end

"""
    myplot([x, y,] img; kwargs...)

Create image of `img` with preferred default values.

# Arguments
- `x::AbstractArray = 1:size(img,1)`: x locations of data points
- `y::AbstractArray = 1:size(img,2)`: y locations of data points
- `img::AbstractArray{<:Number,2}`: 2D data to plot
- `kwargs...`: Keyword arguments passed to `Plots.heatmap`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function myplot(img::AbstractArray{<:Real,2};
    x = 1:size(img,1),
    y = 1:size(img,2),
    color = :grays,
    xticks = [minimum(x), maximum(x)],
    yticks = [minimum(y), maximum(y)],
    aspect_ratio = :equal,
    yflip = true,
    kwargs...
)

    return heatmap(x, y, transpose(img),
                   color = color,
                   xticks = xticks,
                   yticks = yticks,
                   aspect_ratio = aspect_ratio,
                   yflip = yflip;
                   kwargs...)

end

"""
    myplot([x, y, z], img; combine, ncols, npad, kwargs...)

Create image of 3D `img` with preferred default values.

# Arguments
- `x::AbstractArray = 1:size(img,1)`: x locations of data points
- `y::AbstractArray = 1:size(img,2)`: y locations of data points
- `z::AbstractArray = 1:size(img,3)`: z locations of data points
- `img::AbstractArray{<:Number,3}`: 3D data to plot
- `combine::Bool = true`: Whether to create one big 2D image or `length(z)`
    individual 2D images
- `ncols::Integer`: Number of columns of 2D images to display
- `npad::Integer`: Number of pixels of padding between 2D images (only used when
    `combine` is `true`)
- `kwargs...`: Keyword arguments passed to `Plots.heatmap`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function myplot(img::AbstractArray{<:Real,3};
    x = 1:size(img,1),
    y = 1:size(img,2),
    z = 1:size(img,3),
    combine = true,
    ncols = floor(Int, sqrt(length(z))),
    npad = 1,
    xlabel = combine ? "" : ["z = $i" for i in z],
    clims = combine ? (minimum(img), maximum(img)) : [(minimum(img[:,:,iz]), maximum(img[:,:,iz])) for iz = 1:size(img,3)],
    xticks = [minimum(x), maximum(x)],
    yticks = [minimum(y), maximum(y)],
    kwargs...
)

    (nx, ny, nz) = size(img)

    # Compute the number of rows of 2D images to display
    nrows = Int(ceil(nz / ncols))

    if combine
        img2d = clims[1] * ones(eltype(img), nx * ncols + npad * (ncols - 1), ny * nrows + npad * (nrows - 1))
        for r = 1:nrows, c = 1:ncols
            iz = (r - 1) * ncols + c
            if iz > nz
                break
            end
            startx = 1 + (c - 1) * (nx + npad)
            endx = startx - 1 + nx
            starty = 1 + (r - 1) * (ny + npad)
            endy = starty - 1 + ny
            img2d[startx:endx,starty:endy] = img[:,:,iz]
        end
        dx = x[2] - x[1]
        dy = y[2] - y[1]
        newx = cat(dims = 1, x, [[x[1]-npad*dx:dx:x[1]-dx; x] .+ (c - 1) * (x[end] - x[1] + dx * (npad + 1)) for c = 2:ncols]...)
        newy = cat(dims = 1, y, [[y[1]-npad*dy:dy:y[1]-dy; y] .+ (r - 1) * (y[end] - y[1] + dy * (npad + 1)) for r = 2:nrows]...)
        p = myplot(img2d, xlabel = xlabel, clims = clims, xticks = xticks,
                   yticks = yticks, x = newx, y = newy; kwargs...)
    else
        # Plots.jl is kind of finnicky sometimes in this setting...
        plots = [[myplot(img[:,:,iz], x = x, y = y, xlabel = xlabel[iz],
                         clims = clims[iz], xticks = xticks, yticks = yticks;
                         kwargs...) for iz = 1:nz];
                 [plot(framestyle = :none) for n = nz+1:ncols*nrows]]
        p = plot(plots..., layout = (nrows, ncols))
    end

    return p

end

myplot(idx, x; kwargs...) = myplot(x, idx = idx; kwargs...)
myplot!(p, idx, x; kwargs...) = myplot!(p, x, idx = idx; kwargs...)
myplot(x, y, img; kwargs...) = myplot(img, x = x, y = y; kwargs...)
myplot(x, y, z, img; kwargs...) = myplot(img, x = x, y = y, z = z; kwargs...)
myplot!(p; kwargs...) = plot!(p; kwargs...)
myplot(; kwargs...) = plot(; kwargs...)

function myplot(x::Union{<:AbstractArray{<:Complex,1}, <:AbstractArray{<:Complex,2},
                <:AbstractArray{<:Complex,3}}; kwargs...)

    @warn("taking magnitude of complex input")
    myplot(map(z -> abs.(z), x); kwargs...)

end

function myplot!(p::Plots.Plot{<:AbstractBackend}, x::AbstractArray{<:Complex,1}; kwargs...)

    @warn("taking magnitude of complex input")
    myplot!(p, abs.(x); kwargs...)

end

myplot(p::Plots.Plot{<:AbstractBackend}...; kwargs...) = plot(p...; kwargs...)

function myplot(test::Symbol)

    if test == :test1d1

        x = randn(10)
        idx = rand(10)
        display(myplot(idx, x))

    elseif test == :test1d2

        x = [rand(10), randn(100)]
        display(myplot(x))

    elseif test == :test2d1

        img = [x + y for x = 1:100, y = zeros(150)]
        display(myplot(img))

    elseif test == :test3d1

        img = cat(dims = 3, [z * ones(150,125) for z = 1:10]...)
        display(myplot(img))

    elseif test == :test3d2

        img = cat(dims = 3, [z * ones(150,125) for z = 1:10]...)
        x = (-75:74) / 2
        y = (121:245) / 3
        z = 3:12
        display(myplot(x, y, z, img, ncols = 5, npad = 20))

    elseif test == :test3d3

        img = cat(dims = 3, [z * randn(150,125) for z = 1:21]...)
        display(myplot(img, combine = false))

    elseif test == :test3d4

        img = cat(dims = 3, [z * randn(150,125) for z = 1:8]...)
        x = (-75:74) / 2
        y = (121:245) / 2
        z = 3:10
        display(myplot(x, y, z, img, ncols = 4, npad = 20, combine = false))

    end

end

"""
    myscatter([x, ]y; kwargs...)

Create a scatter plot with preferred default values.

# Arguments
- `x::AbstractArray{<:Union{<:Real,AbstractArray{<:Real,1}},1}`: x coordinates of data points
- `y::AbstractArray{<:Union{<:Real,AbstractArray{<:Real,1}},1}`: y coordinates of data points
- `kwargs...`: Keyword arguments passed to `Plots.scatter`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function myscatter(x::AbstractArray{<:Real,1}, y::AbstractArray{<:Real,1};
    label = "",
    markersize = 5,
    kwargs...
)

    return scatter(x, y,
                   label = label,
                   markersize = markersize;
                   kwargs...)

end

function myscatter(x::AbstractArray{<:AbstractArray{<:Real,1},1},
    y::AbstractArray{<:AbstractArray{<:Real,1},1};
    label = 1:length(x),
    kwargs...
)

    p = myscatter(x[1], y[1],
                  label = label[1];
                  kwargs...)
    for i = 2:length(x)
        myscatter!(p, x[i], y[i],
                   label = label[min(i, length(label))];
                   kwargs...)
    end
    return p

end

"""
    myscatter!(p, [x, ]y; kwargs...)

Add scatter plot data to the given plot.
"""
function myscatter!(p::Plots.Plot{<:AbstractBackend},
    x::AbstractArray{<:Real,1}, y::AbstractArray{<:Real,1};
    label = "",
    markersize = 5,
    kwargs...
)

    scatter!(p, x, y,
             label = label,
             markersize = markersize;
             kwargs...)

end

myscatter(y::AbstractArray{<:Real,1}; kwargs...) = myscatter(1:length(y), y; kwargs...)
myscatter(y::AbstractArray{<:AbstractArray{<:Real,1},1}; kwargs...) = myscatter([1:length(y[i]) for i = 1:length(y)], y; kwargs...)
myscatter!(p, y; kwargs...) = myscatter!(p, 1:length(y), y; kwargs...)

function myscatter(test::Symbol)

    if test == :test1

        x = rand(30)
        y = rand(30)
        display(myscatter(x, y))

    elseif test == :test2

        x = [rand(30), randn(10)]
        y = [rand(30), randn(10)]
        display(myscatter(x, y))

    end

end

"""
    myhist(x; kwargs...)

Create a histogram.

# Arguments
- `x::AbstractArray{<:Real,1}`: Data to display
- `kwargs...`: Keyword arguments passed to `Plots.histogram`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function myhist(x::AbstractArray{<:Real,1};
    label = "",
    kwargs...
)

    return histogram(x,
                     label = label;
                     kwargs...)

end

"""
    myhist(x, y; kwargs...)

Create a 2D histogram.

# Arguments
- `x::AbstractArray{<:Real,1}`: x values of data
- `y::AbstractArray{<:Real,1}`: y values of data
- `kwargs...`: Keyword arguments passed to `Plots.histogram`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function myhist(x::AbstractArray{<:Real,1}, y::AbstractArray{<:Real,1};
    color = :kdc,
    aspect_ratio = :equal,
    kwargs...
)

    return histogram2d(x, y,
                       color = color,
                       aspect_ratio = aspect_ratio;
                       kwargs...)

end

function myhist(test::Symbol)

    if test == :test1d1

        x = randn(10000)
        display(myhist(x))

    elseif test == :test2d1

        x = 2randn(10000)
        y = randn(10000)
        display(myhist(x, y))

    end

end

"""
    iplot(...)

Create an interactive plot, i.e., one in which the user can interactively
inspect values at indexes of interest.

# Arguments
All arguments are passed to `myplot`.

# Return
- `p::Plots.Plot{Plots.PlotlyBackend}`: Plot handle
"""
function iplot(args...; kwargs...)

    # Save the current backend to restore later
    cur = backend()

    # Switch to Plotly backend for interactive visualization
    plotly()

    # Create the plot
    p = myplot(args...; kwargs...)

    # Restore the previous backend
    backend(cur)

    # Return the plot
    return p

end

"""
    getroi(x)

Get the index for a rectangular region of interest (ROI) of `x`.

# Arguments
- `x::AbstractArray`: Data for which to get the index for a ROI

# Return
- `roi::CartesianIndices`: Index for ROI of `x`, i.e., `x[roi]` returns the ROI
"""
function getroi(x::AbstractArray)

    # Display x
    display(iplot(x))

    # Compute number of dimensions of x
    N = ndims(x)

    # Create function to parse user input
    f = input -> begin
        out = parse.(Int, split(input))
        if length(out) != N
            error("user provided $(length(out)) numbers, should provide $N")
        else
            return out
        end
    end

    # Have user define two opposite corners of rectangular ROI
    println("Input the index of one corner of the ROI. Separate the indexes " *
            "for the different dimensions with spaces (no other characters).")
    idx1 = getuserinput(f)
    println("Input the index of the other corner of the ROI. Separate the " *
            "indexes for the different dimensions with spaces as before.")
    idx2 = getuserinput(f)

    # Sort the provided indices
    low = min.(idx1, idx2)
    high = max.(idx1, idx2)

    # Construct and return roi
    return CartesianIndex(low...):CartesianIndex(high...)

end

function getroi(test::Symbol)

    if test == :test1

        img = [x + y for x = 1:100, y = zeros(150)]
        roi = getroi(img)
        display(iplot(plotroi(img, roi)))

    end

end

"""
    getuserinput(f)

Get input from the user.

# Arguments
- `f::Function`: Function to apply to line of user input

# Return
- `out`: Output of `f` applied to user input
"""
function getuserinput(f::Function)

    # Keep trying until user gives valid input
    while true
        try
            input = readline()
            # User can exit by typing q
            if input == "q"
                return nothing
            else
                return f(input)
            end
        catch ex
            println(ex)
            println("Invalid input. Try again.")
        end
    end

end

"""
    plotroi(x, roi; fill, value, kwargs)

Display the given region of interest `roi` of `x`.

# Arguments
- `x::AbstractArray`: Data for which to display the ROI
- `roi::CartesianIndices`: ROI to display
- `fill::Bool = false`: Whether to fill in the ROI (`true`) or show only the
    boundary (`false`)
- `value = 1.2maximum(x)`: Value to assign to ROI locations
- `kwargs`: Keyword arguments passed to `myplot`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function plotroi(x::AbstractArray, roi::CartesianIndices;
    fill = false,
    value = 1.2maximum(x),
    kwargs...
)

    # Compute the number of dimensions of x
    N = ndims(x)

    # Make sure the dimensions of x and roi match
    if length(roi[1]) != N
        throw(DimensionMismatch("x has dimension $N, element of roi has dimension $(length(roi[1]))"))
    elseif ndims(roi) != N
        throw(DimensionMismatch("x has dimension $N, roi has dimension $(ndims(roi))"))
    end

    # Copy x to avoid overwriting values in x
    xcopy = copy(x)

    # Replace the values of xcopy in the ROI with the given value for easy visualization
    if fill
        xcopy[roi] .= value
    else
        s = size(roi)
        for d = 1:N
            xcopy[roi[CartesianIndex(ones(Int,d-1)...),:,CartesianIndex(ones(Int,N-d)...)]] .= value
            xcopy[roi[CartesianIndex(s[1:d-1]),:,CartesianIndex(s[d+1:end])]] .= value
        end
    end

    # Return a plot of x with the ROI clearly distinguished
    return myplot(xcopy; kwargs...)

end

function plotroi(test::Symbol)

    if test == :test1

        img = [x + y for x = 1:100, y = zeros(150)]
        roi = CartesianIndex(5,5):CartesianIndex(20,30)
        display(iplot(plotroi(img, roi)))

    elseif test == :test2

        img = [x + y for x = 1:100, y = zeros(150)]
        roi = CartesianIndex(5,5):CartesianIndex(20,30)
        display(iplot(plotroi(img, roi, fill = true, value = 200)))

    end

end

"""
    segment(img; show)

Segment the given image `img`.

# Arguments
- `img::AbstractArray{<:Any,2}`: Image to segment
- `show::Bool = false`: Whether or not to display the segmentation

# Return
- `labels::AbstractArray{Int,2}`: Map of labels (displayed if `show` is `true`)
"""
function segment(img::AbstractArray{<:Any,2}; show = false)

    # Display img
    display(iplot(img))

    # Create function to parse user input
    f = input -> begin
        out = parse.(Int, split(input))
        if length(out) != 3
            error("user provided $(length(out)) numbers, should provide 3")
        else
            return out
        end
    end

    # Have user provide seeds for seeded_region_growing
    println("Input the x and y coordinates and the class label (separated by " *
            "whitespace) of each seed location. When finished, type \"q\".")
    seeds = Array{Tuple{CartesianIndex{2},Int},1}()
    while true
        input = getuserinput(f)
        if isnothing(input)
            break
        else
            push!(seeds, (CartesianIndex(input[1], input[2]), input[3]))
        end
    end

    # Segment img and return the result
    labels = seeded_region_growing(Gray.(img), seeds).image_indexmap

    # Optionally display the segmentation
    if show
        display(myplot(labels))
    end

    return labels

end

function segment(test::Symbol)

    if test == :test1

        img = zeros(200,200)
        img[5:25,5:25] .= 20
        img[30:150,30:150] .= 50
        img[70:100,45:55] .= 10
        labels = segment(img, show = true)

    end

end
