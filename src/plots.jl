"""
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-14


    myplot([idx,] x; kwargs...)

Create plot of `x` with preferred default values.

# Arguments
- `idx::AbstractArray = 1:length(x)`: Locations of data points
- `x::AbstractArray{<:Union{<:Number,<:AbstractArray{<:Number,1}},1}`: 1D data to plot
- `kwargs...`: Keyword arguments passed to `Plots.plot`

# Return
- `p::Plots.Plot{<:AbstractBackend}`: Plot handle
"""
function myplot(x::AbstractArray{<:Union{<:Real,<:AbstractArray{<:Real,1}},1};
    idx = x[1] isa Real ? (1:length(x)) : [1:length(x[i]) for i = 1:length(x)],
    label = x[1] isa Real ? "" : ["$i" for i = 1:length(x)],
    line = (:dash, 2.5),
    marker = (:circle, 7),
    kwargs...
)

    return plot(idx, x,
                label = label,
                line = line,
                marker = marker;
                kwargs...)

end

"""
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-14


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
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-14


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
    ncols = Int(floor(sqrt(length(z)))),
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

myplot(x, y, img; kwargs...) = myplot(img, x = x, y = y; kwargs...)

myplot(x, y, z, img; kwargs...) = myplot(img, x = x, y = y, z = z; kwargs...)

function myplot(x::Union{<:AbstractArray{<:Union{<:Complex,<:AbstractArray{<:Complex,1}},1},
                         <:AbstractArray{<:Complex,2}, <:AbstractArray{<:Complex,3}}; kwargs...)

    @warn("taking magnitude of complex input")
    myplot(map(z -> abs.(z), x); kwargs...)

end

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
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-14


    iplot(...)

Create an interactive plot, i.e., one in which the user can interactively
inspect values at indexes of interest.

# Arguments
All arguments are passed to `Plots.plot`.

# Return
- `p::Plots.Plot{Plots.PlotlyBackend}`: Plot handle
"""
function iplot(args...; kwargs...)

    # Save the current backend to restore later
    cur = backend()

    # Switch to Plotly backend for interactive visualization
    plotly()

    # Create the plot
    p = plot(args...; kwargs...)

    # Restore the previous backend
    backend(cur)

    # Return the plot
    return p

end

"""
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-14


    getroi(x)

Get the index for a rectangular region of interest (ROI) of `x`.

# Arguments
- `x::AbstractArray`: Data for which to get the index for a ROI

# Return
- `roi::CartesianIndices`: Index for ROI of `x`, i.e., `x[roi]` returns the ROI
"""
function getroi(x::AbstractArray{<:Any,N}) where N

    # Display x
    display(iplot(myplot(x)))

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
    roi = CartesianIndex(low...):CartesianIndex(high...)
    return roi

end

"""
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-14


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

"""
function plotroi()



end

"""

"""
function segment()



end
