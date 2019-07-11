"""
    LogUniform

A log-uniform distribution. If X is a uniform distribution with support [a, b],
then exp(X) is a log-uniform distribution with support [exp(a), exp(b)].
"""
struct LogUniform{T<:Real}
    a::T
    b::T

    LogUniform{T}(a::T, b::T) where {T} = begin
        0 < a < b || error("0 < a < b must hold")
        new{T}(a, b)
    end
end

LogUniform(a::T, b::T) where {T<:Real} = LogUniform{T}(a, b)
LogUniform(a::Real, b::Real) = LogUniform(promote(a, b)...)
LogUniform(a::Integer, b::Integer) = LogUniform(Float64(a), Float64(b))
LogUniform() = LogUniform(1.0, ℯ)

Base.rand(rng::AbstractRNG, s::Random.SamplerTrivial{LogUniform{T}}) where {T} = begin
    d = s[]
    return exp(log(d.a) + log(d.b / d.a) * rand(rng))
end

Base.eltype(::Type{LogUniform{T}}) where {T} = T

"""
    Delta

A delta train distribution, where the deltas are not necessarily evenly spaced,
nor do they repeat forever. Essentially, a discrete distribution that allows
floating point values to be realized.
"""
struct Delta{T<:Real}
    x::Array{T,1} # Possible values that can be generated
    p::Array{Float64,1} # Probabilities; Pr(X = x[i]) = p[i]

    Delta{T}(x::Array{T,1}, p::Array{Float64,1}) where {T} = begin
        (sum(p) == 1.0          &&
         !any(p .== 0.0)        &&
         length(x) == length(p) &&
         allunique(x))          || error("Invalid inputs")
        new{T}(x, p)
    end
end

Delta(x::Array{T,1}, p::Array{Float64,1}) where {T<:Real} = Delta{T}(x, p)
Delta(x::Array{<:Integer,1}, p::Array{Float64,1}) = Delta(Array{Float64}(x), p)
Delta(x::Array{<:Real,1}) = Delta(x, ones(length(x)) / length(x))
Delta(x::Real) = Delta([x])
Delta() = Delta(0)

Base.rand(rng::AbstractRNG, s::Random.SamplerTrivial{Delta{T}}) where {T} = begin
    d = s[]
    val = rand(rng)
    for i = 1:length(d.x)
        if val < d.p[i]
            return d.x[i]
        end
        val -= d.p[i]
    end
    return d.x[end]
end

Base.eltype(::Type{Delta{T}}) where {T} = T
