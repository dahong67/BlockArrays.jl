### Views
to_index(::BlockIndexRange) = throw(ArgumentError("BlockIndexRange must be converted by to_indices(...)"))

@inline to_indices(A, inds, I::Tuple{BlockIndexRange{1,R}, Vararg{Any}}) where R =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{BlockIndexRange, Vararg{Any}}) =
    to_indices(A, inds, (BlockRange.(Block.(I[1].block.n), tuple.(I[1].indices))..., tail(I)...))


# In 0.7, we need to override to_indices to avoid calling linearindices
@inline to_indices(A, I::Tuple{BlockIndexRange, Vararg{Any}}) =
    to_indices(A, axes(A), I)

if VERSION >= v"1.2-"  # See also `reindex` definitions in views.jl
    reindex(idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{<:BlockIndexRange}, Vararg{Any}}) =
        (@_propagate_inbounds_meta; (BlockSlice(BlockIndexRange(Block(idxs[1].block.indices[1][Int(subidxs[1].block.block)]),
                                                                subidxs[1].block.indices),
                                                idxs[1].indices[subidxs[1].indices]),
                                    reindex(tail(idxs), tail(subidxs))...))
else  # if VERSION >= v"1.2-"
    reindex(V, idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{<:BlockIndexRange}, Vararg{Any}}) =
        (@_propagate_inbounds_meta; (BlockSlice(BlockIndexRange(Block(idxs[1].block.indices[1][Int(subidxs[1].block.block)]),
                                                                subidxs[1].block.indices),
                                                idxs[1].indices[subidxs[1].indices]),
                                        reindex(V, tail(idxs), tail(subidxs))...))
end  # if VERSION >= v"1.2-"


# _splatmap taken from Base:
_splatmap(f, ::Tuple{}) = ()
_splatmap(f, t::Tuple) = (f(t[1])..., _splatmap(f, tail(t))...)

# De-reference blocks before creating a view to avoid taking `global2blockindex`
# path in `AbstractBlockStyle` broadcasting.
@inline function Base.unsafe_view(
        A::BlockArray{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    @_propagate_inbounds_meta
    B = A[map(x -> x.block.block, I)...]
    return view(B, _splatmap(x -> x.block.indices, I)...)
end

@inline function Base.unsafe_view(
        A::PseudoBlockArray{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    @_propagate_inbounds_meta
    return view(A.blocks, map(x -> x.indices, I)...)
end

@inline function Base.unsafe_view(
        A::ReshapedArray{<:Any, N, <:AbstractBlockArray{<:Any, M}},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N, M}
    @_propagate_inbounds_meta
    # Note: assuming that I[M+1:end] are verified to be singletons
    return reshape(view(A.parent, I[1:M]...), Val(N))
end

@inline function Base.unsafe_view(
        A::Array{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    @_propagate_inbounds_meta
    return view(A, map(x -> x.indices, I)...)
end


"""
    unblock(block_sizes, inds, I)

Returns the indices associated with a block as a `BlockSlice`.
"""
function unblock(A::AbstractArray{T,N}, inds, I) where {T, N}
    B = first(I)
    if length(inds) == 0
        # Allow `ones(2)[Block(1)[1:1], Block(1)[1:1]]` which is
        # similar to `ones(2)[1:1, 1:1]`.
        BlockSlice(B,Base.OneTo(1))
    else
        BlockSlice(B,inds[1][B])
    end
end


to_index(::Block) = throw(ArgumentError("Block must be converted by to_indices(...)"))
to_index(::BlockIndex) = throw(ArgumentError("BlockIndex must be converted by to_indices(...)"))
to_index(::BlockRange) = throw(ArgumentError("BlockRange must be converted by to_indices(...)"))

@inline to_indices(A, inds, I::Tuple{Block{1}, Vararg{Any}}) =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{Block, Vararg{Any}}) =
    to_indices(A, inds, (Block.(I[1].n)..., tail(I)...))

@inline to_indices(A, inds, I::Tuple{BlockRange{1,R}, Vararg{Any}}) where R =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{BlockRange, Vararg{Any}}) =
    to_indices(A, inds, (BlockRange.(tuple.(I[1].indices))..., tail(I)...))


# In 0.7, we need to override to_indices to avoid calling linearindices
@inline to_indices(A, I::Tuple{Block, Vararg{Any}}) =
    to_indices(A, axes(A), I)

@inline to_indices(A, I::Tuple{BlockRange, Vararg{Any}}) =
    to_indices(A, axes(A), I)


# The first argument for `reindex` is removed as of
# https://github.com/JuliaLang/julia/pull/30789 in Julia `Base`.  So,
# we define 2-arg `reindex` for Julia 1.2 and later.
if VERSION >= v"1.2-"

# BlockSlices map the blocks and the indices
# this is loosely based on Slice reindex in subarray.jl
reindex(idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}}) =
    (@_propagate_inbounds_meta; (BlockSlice(BlockRange(idxs[1].block.indices[1][Int.(subidxs[1].block)]),
                                            idxs[1].indices[subidxs[1].indices]),
                                 reindex(tail(idxs), tail(subidxs))...))

reindex(idxs::Tuple{BlockSlice{BlockRange{1,Tuple{UnitRange{Int}}}}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}}) =
    (@_propagate_inbounds_meta; (BlockSlice(Block(idxs[1].block.indices[1][Int(subidxs[1].block)]),
                                            idxs[1].indices[subidxs[1].indices]),
                                 reindex(tail(idxs), tail(subidxs))...))

function reindex(idxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}})
    (idxs[1], reindex(tail(idxs), tail(subidxs))...)
end

else  # if VERSION >= v"1.2-"

reindex(V, idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}}) =
    (@_propagate_inbounds_meta; (BlockSlice(BlockRange(idxs[1].block.indices[1][Int.(subidxs[1].block)]),
                                            idxs[1].indices[subidxs[1].indices]),
                                    reindex(V, tail(idxs), tail(subidxs))...))

reindex(V, idxs::Tuple{BlockSlice{BlockRange{1,Tuple{UnitRange{Int}}}}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}}) =
    (@_propagate_inbounds_meta; (BlockSlice(Block(idxs[1].block.indices[1][Int(subidxs[1].block)]),
                                            idxs[1].indices[subidxs[1].indices]),
                                    reindex(V, tail(idxs), tail(subidxs))...))

function reindex(V, idxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}})
    subidxs[1].block == Block(1) || throw(BoundsError(V, subidxs[1].block))
    (idxs[1], reindex(V, tail(idxs), tail(subidxs))...)
end

end  # if VERSION >= v"1.2-"


#################
# support for pointers
#################

const BlockOrRangeIndex = Union{RangeIndex, BlockSlice}

function unsafe_convert(::Type{Ptr{T}},
                        V::SubArray{T, N, BlockArray{T,N,AT,BS}, <:NTuple{N, BlockSlice{Block{1,Int}}}}) where {AT <: AbstractArray{<:AbstractArray{T,N},N}, BS <: NTuple{N,AbstractUnitRange{Int}}} where {T,N}
    unsafe_convert(Ptr{T}, parent(V).blocks[Int.(Block.(parentindices(V)))...])
end

unsafe_convert(::Type{Ptr{T}}, V::SubArray{T,N,PseudoBlockArray{T,N,AT},<:Tuple{Vararg{BlockOrRangeIndex}}}) where {T,N,AT} =
    unsafe_convert(Ptr{T}, V.parent) + (Base.first_index(V)-1)*sizeof(T)
