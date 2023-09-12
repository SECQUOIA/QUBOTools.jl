@doc raw"""
    Wishart{T}(n::Integer, m::Integer)

Represents the Wishart model on ``n`` variables whose ``W`` matrix has ``m`` columns.
"""
struct Wishart{T} <: AbstractProblem{T}
    n::Int
    m::Int

    discretize::Bool
    precision::Int

    function Wishart{T}(n::Integer, m::Integer; discretize::Bool = false, precision::Integer = 0) where {T}
        @assert precision >= 0

        return new{T}(n, m, discretize, precision)
    end
end

function Wishart(n::Integer, m::Integer; discretize::Bool = false, precision::Integer = 0)
    return Wishart{Float64}(n, m; discretize, precision)
end

function generate(rng, problem::Wishart{T}) where {T}
    f = PBO.wishart(
        rng,
        PBO.PBF{Int,T},
        problem.n,
        problem.m;
        discretize_bonds = problem.discretize,
        precision        = problem.precision,
    )

    return Model{Int,T,Int}(
        f;
        metadata = Dict{String,Any}(
            "origin"    => "Generated by QUBOTools.jl",
            "synthesis" => Dict{String,Any}(
                "model"      => "Wishart",
                "parameters" => Dict{String,Any}(
                    "n" => problem.n,
                    "m" => problem.m,
                ),
            ),
        )
    )
end

