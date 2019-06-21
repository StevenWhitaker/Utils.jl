"""
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-21


    myfill(T, v, dims...)

Create an array of type `T` of the given dimensions where each element is
assigned the value `v`. If `T` is `typeof(v)`, use `Base.fill` instead.

# Arguments
- `T::Type`: Type of elements of the array
- `v`: Value to assign to each array element
- `dims::Integer...`: Dimension of the array

# Return
- `arr::Array{T,length(dims)}`: Array filled with value `v`
"""
myfill(::Type{T}, v::Number, dims...) where {T<:Number} = fill(convert(T, v), dims...)

function myfill(test::Symbol)

    if test == :test1

        myfill(Float64, 9, (2,3))

    elseif test == :test2

        myfill(Complex, 1, 1)

    elseif test == :test3

        myfill(Number, 3.0, 0, 0, 1)

    end

end

"""
Author: Steven Whitaker

Institution: University of Michigan

Date Created: 2019-06-21


    embed([T,] mask, x [, bgval])

Create an array `arr` (optionally of type `T`) of size `size(mask)`, where
`arr[mask] .= x`. The values outside of the mask are given by `bgval`, i.e.,
`arr[.!mask] .= bgval`.

# Arguments
- `T::Type = eltype(x)`: Type of elements of the array
- `mask::AbstractArray{Bool}`: Mask
- `x`: Values to embed into the array
- `bgval = T <: Number ? zero(T) : nothing`: Values of array that are outside
    the mask

# Return
- `arr::Array{T,ndims(mask)}`: Array with values in `mask` specified by `x`
"""
function embed(::Type{T},
    mask::AbstractArray{Bool,N},
    x,
    bgval = T <: Number ? zero(T) : nothing
) where {T,N}

    arr = Array{T,N}(undef, size(mask))
    if !isnothing(bgval)
        arr[.!mask] .= bgval
    end
    arr[mask] .= x
    return arr

end

embed(mask, x, bgval) = embed(eltype(x), mask, x, bgval)
embed(mask, x) = embed(eltype(x), mask, x)

function embed(test::Symbol)

    if test == :test1

        mask = rand(Bool,3,3)
        x = randn(count(mask))
        embed(mask, x)

    elseif test == :test2

        mask = iseven.(1:20)
        x = randn(count(mask))
        embed(mask, x)

    elseif test == :test3

        mask = rand(Bool,2,3,4)
        x = randn(count(mask))
        bgval = -100
        embed(mask, x, bgval)

    elseif test == :test4

        mask = rand(Bool,2,3,4)
        x = randn(count(mask))
        bgval = 100randn(count(.!mask))
        embed(mask, x, bgval)

    elseif test == :test5

        mask = rand(Bool,3,3)
        x = randn(count(mask))
        embed(Complex, mask, x)

    elseif test == :test6

        mask = rand(Bool,3,3)
        x = randn(count(mask))
        bgval = LinRange(10,20,count(.!mask))
        embed(Complex, mask, x, bgval)

    elseif test == :test7

        mask = rand(Bool,3,3)
        x = [n * ones(2,2) for n = 1:count(mask)]
        embed(mask, x)

    elseif test == :test8

        mask = rand(Bool,3,3)
        x = [n * ones(2,2) for n = 1:count(mask)]
        bgval = [zeros(2,2)]
        embed(mask, x, bgval)

    elseif test == :test9

        mask = rand(Bool,3,3)
        x = [n * ones(2,2) for n = 1:count(mask)]
        bgval = [randn(2,2) for n = 1:count(.!mask)]
        embed(Array{Complex,2}, mask, x, bgval)

    elseif test == :test10

        mask = rand(Bool,3,3)
        x = 10
        bgval = 1
        embed(Complex, mask, x, bgval)

    elseif test == :test11

        mask = rand(Bool,3,3)
        x = [100ones(4,2)]
        embed(Array{Complex,2}, mask, x)

    end

end
