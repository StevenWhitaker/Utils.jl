"""
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

# Examples
```jldoctest
julia> embed([true, false, true, true, false], [1, 2, 3])
5-element Array{Int64,1}:
 1
 0
 2
 3
 0

julia> embed(ComplexF64, [false false; true true], [1, 2], 100)
2×2 Array{Complex{Float64},2}:
 100.0+0.0im  100.0+0.0im
   1.0+0.0im    2.0+0.0im
```
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

"""
    squeeze(x)

Drop all singleton dimensions of `x`. Caution: This is not type stable; see
[this post](https://stackoverflow.com/questions/52505760/dropping-singleton-dimensions-in-julia).
Also, if `x` contains only one element (i.e., all of its dimensions are
singletons) then the output will be a zero-dimensional array. Only use this
function if you are sure you are not removing important dimensions and if you
don't care about type stability. For a type-stable version, see
[`@squeeze`](@ref), which is recommended to use.

# Arguments
- `x::AbstractArray`: Input array whose dimensions should be dropped

# Return
- `arr::AbstractArray`: Array containing the same data as `x` but with no
    singleton dimensions; note that `arr` is NOT a copy of `x`, i.e., modifying
    the contents of `arr` will modify the contents of `x`
"""
squeeze(x::AbstractArray) = dropdims(x, dims = Tuple(findall(size(x) .== 1)))

"""
    @squeeze ex

Evaluate the expression `ex` (which is of the form `fun(args...; kwargs...)`,
where `dims` is in `kwargs`) and drop the resulting singleton dimensions
specified by `dims`. Note that `dims` must be explicitly passed; it cannot be
splatted.

# Arguments
- `ex`: Expression to evaluate and whose result to squeeze

# Return
- `result`: Result of evaluating `ex` and squeezing the resulting singleton
    dimensions

# Examples
```jldoctest
julia> @squeeze sum(ones(3, 3), dims = 2)
3-element Array{Float64,1}:
 3.0
 3.0
 3.0

julia> @squeeze mapslices(sum, ones(3,4,5), dims = (1,2))
5-element Array{Float64,1}:
 12.0
 12.0
 12.0
 12.0
 12.0
```
"""
macro squeeze(ex::Expr)

    # $(esc(dropdims)) is to make sure to call dropdims from the caller's
    # context (this is the case for all instances of $(esc(...)))
    # This code searches for the last occurrence of an expression whose first
    # arg is :dims, so hopefully the only such possibility is a keyword
    # argument dims (notably, if a function dims has been defined, that could
    # be a candidate, but I don't think that is likely)
    return :($(esc(dropdims))($(esc(ex)), $(esc(ex.args[findlast(x -> x isa Expr && x.args[1] == :dims, ex.args)]))))

end

function squeeze(test::Symbol)

    if test == :a1

        x = rand(1,3,1,5,6,1,2,1,2,3,1)
        y = squeeze(x)
        @assert x[:] == y[:]
        size(y)

    elseif test == :m1

        x = ones(3,3)
        display(@macroexpand @squeeze sum(x, dims = 2))
        @squeeze(sum(x, dims = 2))

    elseif test == :m2

        display(@macroexpand @squeeze sum(ones(3,3), dims = 2))
        @squeeze sum(ones(3,3), dims = 2)

    elseif test == :m3

        display(@macroexpand @squeeze mapslices(x -> sum(x), ones(3,4,5), dims = (1,2)))
        @squeeze mapslices(x -> sum(x), ones(3,4,5), dims = (1,2))

    elseif test == :m4

        x = ones(3,3)
        display(@macroexpand @squeeze sum(dims = 2, x))
        @squeeze(sum(dims = 2, x))

    elseif test == :m5

        x = [1 2 3; 4 5 6; 7 8 9]
        f = (z; dims) -> mapslices(maximum, z, dims = dims)
        display(@macroexpand @squeeze f(x, dims = 1))
        @squeeze f(x, dims = 1)

    elseif test == :m6

        x = [1 2 3; 4 5 6; 7 8 9]
        display(@macroexpand @squeeze ((z; dims) -> mapslices(maximum, z, dims = dims))(x, dims = 1))
        @squeeze ((z; dims) -> mapslices(maximum, z, dims = dims))(x, dims = 1)

    end

end
