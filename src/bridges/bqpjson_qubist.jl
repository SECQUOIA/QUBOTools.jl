function Base.convert(::Type{<:Qubist}, model::BQPJSON{BoolDomain})
    convert(Qubist{SpinDomain}, convert(BQPJSON{SpinDomain}, model))
end

function Base.convert(::Type{<:Qubist}, model::BQPJSON{SpinDomain})
    backend = copy(model.backend)
    sites   = isempty(backend.variable_map) ? 0 : 1 + maximum(keys(backend.variable_map))
    lines   = length(backend.linear_terms) + length(backend.quadratic_terms)

    Qubist{SpinDomain}(
        backend,   
        sites,
        lines,
    )
end

function BQPIO.isvalidbridge(
    source::BQPJSON{SpinDomain},
    target::BQPJSON{SpinDomain},
    ::Type{<:Qubist{SpinDomain}};
    kws...
)
    BQPIO.isvalidbridge(
        BQPIO.backend(source),
        BQPIO.backend(target);
        kws...
    )
end

function Base.convert(::Type{<:BQPJSON{BoolDomain}}, model::Qubist)
    convert(BQPJSON{BoolDomain}, convert(BQPJSON{SpinDomain}, model))
end

function Base.convert(::Type{<:BQPJSON{SpinDomain}}, model::Qubist)
    backend   = copy(model.backend)
    solutions = nothing

    BQPJSON{SpinDomain}(backend, solutions)
end

function BQPIO.isvalidbridge(
    source::Qubist{SpinDomain},
    target::Qubist{SpinDomain},
    ::Type{<:BQPJSON{SpinDomain}};
    kws...
)
    BQPIO.isvalidbridge(
        BQPIO.backend(source),
        BQPIO.backend(target);
        kws...
    )
end