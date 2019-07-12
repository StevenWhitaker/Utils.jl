"""
    Interpolator

Abstract type for describing interpolators.
"""
abstract type Interpolator end

"""
    NearestInterpolator([pos, ]val) <: Interpolator

Create a nearest-neighbor interpolator.

# Properties
- `pos::AbstractArray{<:AbstractArray{<:Any,1},1} = [1:N[i] for i = 1:D]`:
    Positions of corresponding values, i.e., the position of `val[i...]` is
    given by `(pos[1][i[1]], pos[2][i[2]], ...)`; the default is the
    traditional 1-based indexing, i.e., `pos[i...] == i`
- `val::Array`: Values from which to interpolate
"""
struct NearestInterpolator{T,P<:AbstractArray{<:AbstractArray{<:Any,1},1},N} <: Interpolator
    val::Array{T,N}
    pos::P

    NearestInterpolator(val::Array{T,N}, pos::P) where {T,P<:AbstractArray{<:AbstractArray{<:Any,1},1},N} = begin
        length(pos) == N ||
            throw(ArgumentError("length(pos) must be N"))
        size(val) == Tuple([length(pos[i]) for i = 1:N]) ||
            throw(ArgumentError("length of each element of pos must equal the size of the corresponding dimension of val"))
        new{T,P,N}(val, pos)
    end

    NearestInterpolator(val::Array{T,N}) where {T,N} = begin
        pos = [1:size(val, n) for n = 1:N]
        new{T,typeof(pos),N}(val, pos)
    end
end

"""
    NearestInterpolator(pos)

Find the nearest data point to the given position.
"""
function (interp::NearestInterpolator{T,P,N})(pos::Vararg{Any,N}) where {T,P,N}

    interp.val[[argmin(abs.(interp.pos[n] .- pos[n])) for n = 1:N]...]

end
