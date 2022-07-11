@doc raw"""
""" function isapproxdict end

function isapproxdict(x::Dict{K,T}, y::Dict{K,T}; kw...) where {K,T<:Real}
    (length(x) == length(y)) && all(haskey(y, k) && isapprox(x[k], y[k]; kw...) for k in keys(x))
end

@doc raw"""
""" function swapdomain end

function swapdomain(
    ::Type{<:SpinDomain},
    ::Type{<:BoolDomain},
    linear_terms::Dict{Int,T},
    quadratic_terms::Dict{Tuple{Int,Int},T},
    offset::Union{T,Nothing},
) where {T}

    bool_offset = isnothing(offset) ? zero(T) : offset
    bool_linear_terms = Dict{Int,T}()
    bool_quadratic_terms = Dict{Tuple{Int,Int},T}()

    for (i, h) in linear_terms
        bool_linear_terms[i] = get(bool_linear_terms, i, zero(T)) + 2h
        bool_offset -= h
    end

    for ((i, j), Q) in quadratic_terms
        bool_quadratic_terms[(i, j)] = get(bool_quadratic_terms, (i, j), zero(T)) + 4Q
        bool_quadratic_terms[(i, i)] = get(bool_quadratic_terms, (i, i), zero(T)) - 2Q
        bool_quadratic_terms[(j, j)] = get(bool_quadratic_terms, (j, j), zero(T)) - 2Q
        bool_offset += Q
    end

    if isnothing(offset)
        (bool_linear_terms, bool_quadratic_terms, nothing)
    else
        (bool_linear_terms, bool_quadratic_terms, bool_offset)
    end
end

function swapdomain(
    ::Type{<:BoolDomain},
    ::Type{<:SpinDomain},
    linear_terms::Dict{Int,T},
    quadratic_terms::Dict{Tuple{Int,Int},T},
    offset::Union{T,Nothing}
) where {T}

    spin_offset = isnothing(offset) ? zero(T) : offset
    spin_linear_terms = Dict{Int,T}()
    spin_quadratic_terms = Dict{Tuple{Int,Int},T}()

    for (i, q) in linear_terms
        spin_linear_terms[i] = get(spin_linear_terms, i, zero(T)) + q / 2
        spin_offset += q / 2
    end

    for ((i, j), Q) in quadratic_terms
        spin_quadratic_terms[(i, j)] = get(spin_quadratic_terms, (i, j), zero(T)) + Q / 4
        spin_quadratic_terms[(i, i)] = get(spin_quadratic_terms, (i, i), zero(T)) + Q / 4
        spin_quadratic_terms[(j, j)] = get(spin_quadratic_terms, (j, j), zero(T)) + Q / 4
        spin_offset += Q / 4
    end

    if isnothing(offset)
        (spin_linear_terms, spin_quadratic_terms, nothing)
    else
        (spin_linear_terms, spin_quadratic_terms, spin_offset)
    end
end

@doc raw"""
""" function build_varmap end

function build_varmap(linear_terms::Dict{Int,T}, quadratic_terms::Dict{Tuple{Int,Int},T}) where {T}
    variables = Set{Int}()

    for i in keys(linear_terms)
        push!(variables, i)
    end

    for (i, j) in keys(quadratic_terms)
        push!(variables, i, j)
    end

    Dict{Int,Int}(
        i => k for (k, i) in enumerate(sort(collect(variables)))
    )
end

@doc raw"""
""" function build_varinv end

function build_varinv(variable_map::Dict{Int,Int})
    Dict{Int,Int}(i => k for (k, i) in variable_map)
end

@doc raw"""
""" function build_varbij end

function build_varbij(linear_terms::Dict{Int,T}, quadratic_terms::Dict{Tuple{Int,Int},T}) where {T}
    variable_map = build_varmap(linear_terms, quadratic_terms)
    variable_inv = build_varinv(variable_map)

    return (variable_map, variable_inv)
end

@doc raw"""
""" function normalize end

function normalize(linear_terms::Dict{Int,T}, quadratic_terms::Dict{Tuple{Int,Int},T}) where {T}
    normal_linear_terms = Dict{Int,T}()
    normal_quadratic_terms = Dict{Tuple{Int,Int},T}()

    sizehint!(normal_linear_terms, length(linear_terms))
    sizehint!(normal_quadratic_terms, length(quadratic_terms))

    for (i, l) in linear_terms
        l += get(normal_linear_terms, i, zero(T))
        if iszero(l)
            delete!(normal_linear_terms, i)
        else
            normal_linear_terms[i] = l
        end
    end

    for ((i, j), q) in quadratic_terms
        if i == j
            q += get(normal_linear_terms, i, zero(T))
            if iszero(q)
                delete!(normal_linear_terms, i)
            else
                normal_linear_terms[i] = q
            end
        elseif i < j
            q += get(normal_quadratic_terms, (i, j), zero(T))
            if iszero(q)
                delete!(normal_quadratic_terms, (i, j))
            else
                normal_quadratic_terms[(i, j)] = q
            end
        else # i > j
            q += get(normal_quadratic_terms, (j, i), zero(T))
            if iszero(q)
                delete!(normal_quadratic_terms, (j, i))
            else
                normal_quadratic_terms[(j, i)] = q
            end
        end
    end

    return (normal_linear_terms, normal_quadratic_terms)
end