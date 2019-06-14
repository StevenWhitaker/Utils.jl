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
    idx = x[1] isa Real ? 1:length(x) : [1:length(x[i]) for i = 1:length(x)],
    label = x[1] isa Real ? "" : ["$i" for i = 1:length(x)],
    line = (:dash, 2.5),
    marker = (:circle, 7)
)

    return plot(idx, x,
                label = label,
                line = line,
                marker = marker;
                kwargs...)

end

myplot(idx, x; kwargs...) = myplot(x, idx = idx; kwargs...)

function myplot(x::AbstractArray{<:Union{<:Complex,<:AbstractArray{<:Complex,1}},1}; kwargs...)

    @warn("taking magnitude of complex input")
    myplot(map(z -> abs.(z), x); kwargs...)

end

"""
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-14


    myplot([x, y,] img; kwargs...)

Create image of `img` with preferred default values.
"""
function myplot(x::AbstractArray{<:Real,2})



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
