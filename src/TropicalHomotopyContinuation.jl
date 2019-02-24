module TropicalHomotopyContinuation

export MixedCell, MixedSubdivision, TermOrdering, cayley

import LinearAlgebra

"""
    cayley(Aᵢ...)

Construct the cayley matrix of the given point configurations.
"""
cayley(A::AbstractMatrix...) = cayley(A)
function cayley(A)
    n = size(A[1], 1)
    I = eltype(A[1])
    # make sure that all matrices have the same number of rows
    for i=2:length(A)
        size(A[i], 1) == n || error("Matrices do not have the same number of rows.")
    end
    m = sum(size.(A, 2))
    C = zeros(I, 2n, m)
    j = 1
    for (i, Aᵢ) in enumerate(A), k in 1:size(Aᵢ, 2)
        C[1:n, j] = Aᵢ[:, k]
        C[n+i, j] = one(I)
        j += 1
    end
    C
end

################
# Term Ordering
################
abstract type TermOrdering end
struct LexicographicOrdering <: TermOrdering end

"""
    DotOrdering(w, tiebreaker=LexicographicOrdering())

The term ordering represented by
```math
c₁ < c₂ ⟺ (⟨w,c₁⟩ < ⟨w,c₂⟩) ∨ (⟨w,c₁⟩ = ⟨w,c₂⟩ ∧ c₁ ≺ c₂)
```
where ``≺`` is the term ordering represented by `tiebreaker`.
"""
struct DotOrdering{T<:Number,Ord<:TermOrdering} <: TermOrdering
    w::Vector{T}
    tiebraker::Ord
end
DotOrdering(w::Vector) = DotOrdering(w, LexicographicOrdering())


#######################
# CayleyIndexing
#######################

"""
    CayleyIndex(i, j, offset)

Fields:

* `config_index::Int`
* `col_index::Int`
* `offset::Int`
* `cayley_index::Int`
"""
struct CayleyIndex
    config_index::Int
    col_index::Int
    offset::Int
    cayley_index::Int
end
CayleyIndex(i, j, offset) = CayleyIndex(i, j, offset, offset + j)

"""
    CayleyIndexing

Utility to match the index of the `j`-th column in the `i`-th configuration to its index
in the cayley configuration.

Supports indexing with a configuration and column index.
"""
struct CayleyIndexing
    configuration_sizes::Vector{Int}
    ncolumns::Int # = sum(configuration_sizes)
    nconfigurations::Int
    offsets::Vector{Int}
end
function CayleyIndexing(configuration_sizes::Vector{Int})
    ncolumns = sum(configuration_sizes)
    nconfigurations = length(configuration_sizes)
    offsets = cumsum([1; configuration_sizes[1:end-1]]) .- 1
    CayleyIndexing(configuration_sizes, ncolumns, nconfigurations, offsets)
end
CayleyIndexing(config_sizes) = CayleyIndexing(collect(config_sizes))

function Base.copy(CI::CayleyIndexing)
    CayleyIndexing(CI.configuration_sizes, CI.ncolumns, CI.nconfigurations, CI.offsets)
end

"""
    offsets(cayley_indexing)

Precomputed offsets of the configuration.
"""
offsets(CI::CayleyIndexing) = CI.offsets

"""
    offset(cayley_indexing, i)

Indexing offset of the `i`-th configuration.
"""
offset(CI::CayleyIndexing, i) = CI.offsets[i]

"""
    nconfigurations(cayley_indexing)

The number of point configurations.
"""
nconfigurations(CI::CayleyIndexing) = CI.nconfigurations

"""
    ncolumns(cayley_indexing)

The number of columns of the cayley matrix
"""
ncolumns(CI::CayleyIndexing) = CI.ncolumns

Base.@propagate_inbounds Base.getindex(CI::CayleyIndexing, i, j) = CI.offsets[i] + j

# iteration protocol
Base.length(C::CayleyIndexing) = C.ncolumns
Base.eltype(C::Type{CayleyIndexing}) = NTuple{3, Int}
function Base.iterate(CI::CayleyIndexing)
    i = j = 1
    @inbounds offset = CI.offsets[i]
    CayleyIndex(i, j, offset), (i, j)
end
function Base.iterate(CI::CayleyIndexing, state)
    i, j = state
    @inbounds mᵢ = CI.configuration_sizes[i]
    if j == mᵢ
        j = 1
        i += 1
    else
        j += 1
    end
    i > CI.nconfigurations && return nothing
    @inbounds offset = CI.offsets[i]
    CayleyIndex(i, j, offset), (i, j)
end

"""
    MixedCell(indices, cayley_matrix, indexing)


"""
mutable struct MixedCell{I<:Integer}
    # A mixed cell is defined by two vectors our of each configuration.
    # We assume that each point is in ℤⁿ and the i-th configuration has mᵢ points.
    # Therefore, the Cayley configuration has ∑ mᵢ =: m columns and 2n rows.
    # We store the indices of the columns.
    indices::Vector{NTuple{2,Int}}

    # The mixed cell cone of a mixed cell is the set of all weight vectors ω such that
    # this mixed cell is a mixed cell of the induced subdivision.
    # The facets of the mixed cell cone can be described by inequalities of the form c⋅ω ≥ 0.
    # The cone is described by m - 2n facets, one for each column of the Cayley matrix
    # which is not part of the mixed cell.
    # The `c`s are sparse, they only have 2n+1 non-zero entries.
    # The entries of the support of the `c`s are the 1-dimensional kernel of the 2n × 2n+1 matrix
    # obtained by picking the 2n columns from the mixed cell and one additional column.
    # We can scale the `c`s such that the entry corresponding
    # to the additional column has the value -volume(mixed cell).
    # Then the other entries of `c` are also integers.
    # To compactly store the `c`s we only need to store n entries.
    # There are two entries associated to each configuration but three entries to the
    # configuration where we picked the addtional column from.
    # If we only have two entries, these have the same absolute value and just different signs.
    # If we have 3 values, then one value (the one corresponding to the additional column)
    # has as value -volume(mixed cell) and the sum of all three needs to add to 0.
    # So if we store the volume, we only need to store on other entry.
    # So as a result it is suffcient to everything in a m × n matrix
    circuit_table::Matrix{I}
    volume::I

    indexing::CayleyIndexing # we store these duplicates
end

function MixedCell(indices, cayley::Matrix, indexing::CayleyIndexing)
    table, volume = circuit_table(indices, cayley, indexing)
    MixedCell(indices, table, volume, indexing)
end

function Base.copy(M::MixedCell)
    MixedCell(copy(M.indices), copy(M.circuit_table), copy(M.volume), copy(M.indexing))
end

function Base.:(==)(M₁::MixedCell, M₂::MixedCell)
    M₁.volume == M₂.volume &&
    M₁.indices == M₂.indices &&
    M₁.circuit_table == M₂.circuit_table
end

function circuit_table(mixed_cell_indices, cayley::Matrix{I}, indexing::CayleyIndexing) where {I}
    D = mixed_cell_submatrix(cayley, indexing, mixed_cell_indices)
    n, m = nconfigurations(indexing), ncolumns(indexing)
    volume = round(Int, abs(LinearAlgebra.det(D)))

    # We need to compute the initial circuits from scratch
    table = zeros(I, m, n)
    D⁻¹ = LinearAlgebra.inv(D)
    for ind in indexing
        aᵢ, bᵢ = mixed_cell_indices[ind.config_index]
        # we can ignore columns corresponding to the support of the mixed cell
        (ind.col_index == aᵢ || ind.col_index == bᵢ) && continue

        # compute a circuit
        x = D⁻¹ * cayley[:, ind.cayley_index]
        x .*= volume

        # we pick every second entry of x
        for (k, l) in enumerate(1:2:2n)
            table[ind.cayley_index, k] = round(Int, x[l])
        end
    end

    table, volume
end

function mixed_cell_submatrix(C::Matrix, indexing::CayleyIndexing, mixed_cell_indices)
    mixed_cell_submatrix!(similar(C, size(C, 1), size(C,1)), C, indexing, mixed_cell_indices)
end
function mixed_cell_submatrix!(D, C::Matrix, indexing::CayleyIndexing, mixed_cell_indices)
    j = 1
    for i in 1:nconfigurations(indexing)
        aᵢ, bᵢ = mixed_cell_indices[i]
        for k in 1:size(C, 1)
            D[k, j]   = C[k, indexing[i, aᵢ]]
            D[k, j+1] = C[k, indexing[i, bᵢ]]
        end
        j += 2
    end
    D
end

Base.@propagate_inbounds function is_valid_inquality(M::MixedCell, I::CayleyIndex)
    aᵢ, bᵢ = M.indices[I.config_index]
    aᵢ != I.col_index && bᵢ != I.col_index
end

"""
    circuit_first(cell::MixedCell, ineq::CayleyIndex, configuration::Int)

Return the first entry of the circuit corresponding to the given configuration.
"""
Base.@propagate_inbounds function circuit_first(cell::MixedCell, ineq::CayleyIndex, i)
    cell.circuit_table[ineq.cayley_index, i]
end

"""
    circuit_second(cell::MixedCell, ineq::CayleyIndex, configuration::Int)

Return the second entry of the circuit corresponding to the given configuration.
"""
Base.@propagate_inbounds function circuit_second(cell::MixedCell, ineq::CayleyIndex, i)
    if i == ineq.config_index
        cell.volume - cell.circuit_table[ineq.cayley_index, i]
    else
        -cell.circuit_table[ineq.cayley_index, i]
    end
end

"""
    inequality_coordinate(cell::MixedCell, ineq::CayleyIndex, coord::CayleyIndex)
    inequality_coordinate(cell::MixedCell, ineq::CayleyIndex, i, j)

Get the coordinate given by `coord` of the mixed cell cone inequality given by `ineq`.
"""
function inequality_coordinate(cell::MixedCell, ineq::CayleyIndex, coord::CayleyIndex)
    inequality_coordinate(cell, ineq, coord.config_index, coord.col_index)
end
function inequality_coordinate(cell::MixedCell, ineq::CayleyIndex, i::Int, j::Int)
    aᵢ, bᵢ = cell.indices[i]

    if i == ineq.config_index && j == ineq.col_index
        -cell.volume
    elseif j == aᵢ
        circuit_first(cell, ineq, i)
    elseif j == bᵢ
        circuit_second(cell, ineq, i)
    else
        zero(cell.volume)
    end
end

function inequality_coordinates(cell::MixedCell, ineq1, ineq2, coord...)
    inequality_coordinate(cell, ineq1, coord...), inequality_coordinate(cell, ineq2, coord...)
end

"""
    inequality_dot(cell::MixedCell, ineq::CayleyIndex, τ)

Compute the dot product of the given inequality with `τ`.
"""
function inequality_dot(cell::MixedCell, ineq::CayleyIndex, τ)
    out = -cell.volume * τ[ineq.cayley_index]
    for i in 1:length(cell.indices)
        aᵢ, bᵢ = cell.indices[i]
        c₁ = circuit_first(cell, ineq, i)
        c₂ = circuit_second(cell, ineq, i)
        out += c₁ * τ[cell.indexing[i, aᵢ]]
        out += c₂ * τ[cell.indexing[i, bᵢ]]
    end
    out
end

"""
    first_violated_inequality(mixed_cell::MixedCell{I}, τ::Vector, ord::TermOrdering)

Compute the first violated inequality in the given mixed cell with respect to the given
term ordering and the target weight vector `τ`.
"""
function first_violated_inequality(mixed_cell::MixedCell{In}, τ::Vector, ord::TermOrdering) where {In}
    empty = true
    best_index = first(mixed_cell.indexing)
    best_dot = zero(In)

    for I in mixed_cell.indexing
        is_valid_inquality(mixed_cell, I) || continue
        dot_I = inequality_dot(mixed_cell, I, τ)
        if dot_I < 0
            # TODO: Can we avoid this check sometimes?
            if empty || circuit_less(cell, I, dot_I, best_index, best_dot)
                empty = false
                best_index = I
                best_dot = dot_I
            end
        end
    end

    return best_index
end

function circuit_less(cell::MixedCell, ind₁::CayleyIndex, λ₁, ind₂::CayleyIndex, λ₂, ord::DotOrdering)
    a = λ₁ * circuit_dot(cell, ind₁, ord.w)
    b = λ₂ * circuit_dot(cell, ind₂, ord.w)
    a == b ? circuit_less(cell, ind₁, λ₁, ind₂, λ₂, ord.tiebraker) : a < b
end

function circuit_less(cell::MixedCell, ind₁::CayleyIndex, λ₁, ind₂::CayleyIndex, λ₂, ord::LexicographicOrdering)
    for (i, (aᵢ, bᵢ)) in enumerate(cell.indices)
        sorted, n = begin
            if ind₁.config_index == ind₂.config_index == i
                swapsort4(aᵢ, bᵢ, ind₁.col_index, ind₂.col_index), 4
            elseif ind₁.config_index == i
                swapsort4(aᵢ, bᵢ, ind₁.col_index), 3
            elseif d.config_index == i
                swapsort4(aᵢ, bᵢ, ind₂.col_index), 3
            else
                swapsort4(aᵢ, bᵢ), 2
            end
        end
        for k in 1:n
            j = sorted[k]
            c₁, c₂ = inequality_coordinates(cell, ind₁, ind₂, i, j)
            λc₁, λc₂ = λ₁ * c₁, λ₂ * c₂
            if λc₁ < λc₂
                return true
            elseif λc₁ > λc₂
                return false
            end
        end
    end
    return false
end


"""
    swapsort4(a, b)
    swapsort4(a, b, c)
    swapsort4(a, b, c, d)

Sorting networks to sort 2, 3, and 4 elements. Always returns a tuple with 4 elements,
where if necessary the tuple is padded with zeros.
"""
function swapsort4(a, b)
    a, b = minmax(a, b)
    (a, b, zero(a), zero(a))
end
function swapsort4(a, b, c)
    b, c = minmax(b, c)
    a, c = minmax(a, c)
    a, b = minmax(a, b)
    return (a, b, c, zero(a))
end
function swapsort4(a, b, c, d)
    a, b = minmax(a, b)
    c, d = minmax(c, d)
    a, c = minmax(a, c)
    b, d = minmax(b, d)
    b, c = minmax(b, c)
    return a, b, c, d
end

@enum CellUpdateCase begin
    cell_update_first
    cell_update_second
    cell_update_first_and_second
end

"""
    CellUpdate(cell::MixedCell, violated_ineq::CayleyIndex)

Compute the updates to the given mixed cell for the first violated inequality.
This doesn't update anything yet but gives a plan what needs to be changed.
This follows the reverse search rule outlined in section 6.2.
"""
struct CellUpdate
    case::CellUpdateCase
    index::CayleyIndex
end

function CellUpdate(cell::MixedCell, index::CayleyIndex)
    i = index.config_index
    aᵢ, bᵢ = cell.indices[i]
    γᵢ = index.col_index

    c_aᵢ = inequality_coordinate(cell, index, index.config_index, aᵢ)
    c_bᵢ = inequality_coordinate(cell, index, index.config_index, bᵢ)

    if c_aᵢ > 0 && c_bᵢ > 0
        CellUpdate(cell_update_first_and_second, index)
    elseif c_aᵢ > 0 && c_bᵢ == 0
        CellUpdate(cell_update_first, index)
    elseif c_aᵢ > 0 && c_bᵢ < 0 && bᵢ < γᵢ
        CellUpdate(cell_update_first, index)
    elseif c_aᵢ == 0 && c_bᵢ > 0
        CellUpdate(cell_update_second, index)
    else # only remaining case:  c_aᵢ < 0 && c_bᵢ > 0 && aᵢ < γᵢ
        CellUpdate(cell_update_second, index)
    end

end

@enum Exchange begin
    exchange_first
    exchange_second
end

"""
    exchange_column!(cell::MixedCell, exchange::Exchange, ineq::CayleyIndex)

Exchange either the first or second column (depending on `exchange`) in the
configuration defined by `ineq` with the column defined in `ineq`.
"""
function exchange_column!(cell::MixedCell, exchange::Exchange, ineq::CayleyIndex)
    i = ineq.config_index
    new_volume = circuit(cell, exchange, ineq, i)

    rotated_in_ineq = cell.circuit_table[ineq.cayley_index, :] # c_4
    if exchange == exchange_first
        rotated_in_ineq[i] -= cell.volume
    end

    rotated_column = [circuit(cell, exchange, r, ineq.config_index) for r in cell.indexing]

    for k in 1:ncolumns(cell.indexing)
        cell.circuit_table[k, :] .= div.(new_volume .* cell.circuit_table[k, :] .- rotated_column[k] .* rotated_in_ineq, cell.volume)
    end

    #  he violated ineq is now an ineq at the old index
    if exchange == exchange_first
        rotated_out = CayleyIndex(i, cell.indices[i][1], ineq.offset)
    else
        rotated_out = CayleyIndex(i, cell.indices[i][2], ineq.offset)
    end

    cell.circuit_table[rotated_out.cayley_index, :] = -rotated_in_ineq
    if exchange == exchange_first
        cell.circuit_table[rotated_out.cayley_index, i] += new_volume
    end

    cell.volume = new_volume
    cell.indices[i] = begin
        if exchange == exchange_first
            (ineq.col_index, cell.indices[i][2])
        else # exchange == exchange_second
            (cell.indices[i][1], ineq.col_index)
        end
    end

    # clear table for ineqs corresponding to mixed cell columns
    for j in 1:nconfigurations(cell.indexing)
        aⱼ, bⱼ = cell.indices[j]
        off = offset(cell.indexing, j)
        cell.circuit_table[aⱼ + off, :] .= zero(eltype(cell.circuit_table))
        cell.circuit_table[bⱼ + off, :] .= zero(eltype(cell.circuit_table))
    end

    cell
end
function exchange_column(cell::MixedCell, exchange::Exchange, ineq::CayleyIndex)
    exchange_column!(copy(cell), exchange, ineq)
end

function Base.reverse(ineq::CayleyIndex, cell::MixedCell, exchange::Exchange)
    if exchange == exchange_first
        j = cell.indices[ineq.config_index][1]
    else # exchange == exchange_second
        j = cell.indices[ineq.config_index][2]
    end
    ind = CayleyIndex(ineq.config_index, j, ineq.offset)
end

Base.@propagate_inbounds function circuit(cell::MixedCell, exchange::Exchange, ineq::CayleyIndex, i)
    if exchange == exchange_first
        circuit_first(cell, ineq, i)
    else # exchange == exchange_second
        circuit_second(cell, ineq, i)
    end
end


"""
    MixedSubdivision(configurations::Vector{<:Matrix}, cell_indices::Vector{Vector{NTuple{2,Int}}})
"""
struct MixedSubdivision{I<:Integer}
    mixed_cells::Vector{MixedCell{I}}
    cayley::Matrix{I}
end

function MixedSubdivision(configurations::Vector{<:Matrix}, cell_indices::Vector{Vector{NTuple{2,Int}}})
    C = cayley(configurations)
    indexing = CayleyIndexing(size.(configurations, 2))
    mixed_cells = map(cell -> MixedCell(cell, C, indexing), cell_indices)
    MixedSubdivision(mixed_cells, C)
end


end # module
