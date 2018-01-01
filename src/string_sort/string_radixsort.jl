import Base: Forward, ForwardOrdering, Reverse, ReverseOrdering, Lexicographic, LexicographicOrdering, sortperm, Ordering, 
            setindex!, getindex, similar
import SortingAlgorithms: RadixSort, RadixSortAlg
"""
    load_bits([type,] s, skipbytes)

Load the underlying bits of a string `s` into a `type` of the user's choosing.
The default is `UInt`, so on a 64 bit machine it loads 64 bits (8 bytes) at a time.
If the `String` is shorter than 8 bytes then it's padded with 0. 

Assumes machine is little-endian

- `type`:       any bits type that has `>>`, `<<`, and `&` operations defined
- `s`:          a `String`
- `skipbytes`:  how many bytes to skip e.g. load_bits("abc", 1) will load "bc" as bits
"""
load_bits(s::String, skipbytes = 0) = load_bits(UInt, s, skipbytes)

function load_bits(::Type{T}, s::String, skipbytes = 0) where T
    n = sizeof(s)
    if n < skipbytes
        return zero(T)
    elseif n - skipbytes >= sizeof(T)
        return ntoh(unsafe_load(Ptr{T}(pointer(s, skipbytes+1))))
    else
        ns = (sizeof(T) - min(sizeof(T), n - skipbytes))*8
        h = unsafe_load(Ptr{T}(pointer(s, skipbytes+1)))
        h = h << ns
        h = h >> ns
        return ntoh(h)
    end
end


"""
    sort! sort strings
"""
# https://discourse.julialang.org/t/redundant-sort-sortperm-options-why/5631 ordering seem redundant and is confusing
function sort!(svec::AbstractVector{String}, lo::Int, hi::Int, ::RadixSortAlg, o::O) where O <: Union{ForwardOrdering, ReverseOrdering, LexicographicOrdering}
    #  Input checking
    println(o == Reverse)
    # return
    if lo >= hi;  return svec;  end

    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
       if lens > 8
            skipbytes = max(0, skipbytes - 16)
            if o == Reverse
                sorttwo!(.~load_bits.(UInt128, svec, skipbytes), svec)
            else
                sorttwo!(load_bits.(UInt128, svec, skipbytes), svec)
            end
            lens -= 16
        elseif lens > 4
            skipbytes = max(0, skipbytes - 8)
            if o == Reverse
                sorttwo!(.~load_bits.(UInt64, svec, skipbytes), svec)
            else
                sorttwo!(load_bits.(UInt64, svec, skipbytes), svec)
            end
            lens -= 8
        else
            skipbytes = max(0, skipbytes - 4)
            if o == Reverse
                sorttwo!(.~load_bits.(UInt32, svec, skipbytes), svec)
            else
                sorttwo!(load_bits.(UInt32, svec, skipbytes), svec)
            end
            lens -= 4
        end
    end
    svec
end

function sortperm_radixsort(svec::AbstractVector{String}; rev::Union{Bool,Void}=nothing, o::Ordering=Forward)
    #  Input checking
    # println(o == Reverse)
    # return
    # if lo >= hi;  return svec;  end
    siv = StringIndexVector(copy(svec), fcollect(length(svec)))

    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
       if lens > 8
            skipbytes = max(0, skipbytes - 16)
            if o == Reverse
                sorttwo!(.~load_bits.(UInt128, siv.svec, skipbytes), siv)
            else
                sorttwo!(load_bits.(UInt128, siv.svec, skipbytes), siv)
            end
            lens -= 16
        elseif lens > 4
            skipbytes = max(0, skipbytes - 8)
            if o == Reverse
                sorttwo!(.~load_bits.(UInt64, siv.svec, skipbytes), siv)
            else
                sorttwo!(load_bits.(UInt64, siv.svec, skipbytes), siv)
            end
            lens -= 8
        else
            skipbytes = max(0, skipbytes - 4)
            if o == Reverse
                sorttwo!(.~load_bits.(UInt32, siv.svec, skipbytes), siv)
            else
                sorttwo!(load_bits.(UInt32, siv.svec, skipbytes), siv)
            end
            lens -= 4
        end
    end
    siv.index
end

using DataFrames
struct StringIndexVector
    svec::Vector{String}
    index::Vector{Int}
end

# function setindex!(siv::StringIndexVector, X::StringIndexVector, inds)
#     if length(X.svec) == 1
#         siv.svec[inds] = X.svec[1]
#         siv.index[inds] = X.index[1]
#     else
#         siv.svec[inds] = X.svec
#         siv.index[inds] = X.index
#     end
# end

function setindex!(siv::StringIndexVector, X::StringIndexVector, inds)
    siv.svec[inds] = X.svec
    siv.index[inds] = X.index
end

function setindex!(siv::StringIndexVector, X, inds)
    siv.svec[inds] = X[1]
    siv.index[inds] = X[2]
end

getindex(siv::StringIndexVector, inds::Integer) = siv.svec[inds], siv.index[inds]
getindex(siv::StringIndexVector, inds...) = StringIndexVector(siv.svec[inds...], siv.index[inds...])
similar(siv::StringIndexVector) = StringIndexVector(similar(siv.svec), similar(siv.index))


"""
    radixsort!(vector_string)

Radixsort on strings

    svec - a vector of strings; sorts it by bits
"""
radixsort_lsd!(x) = radixsort_lsd24!(x)

function radixsort_lsd16!(svec::Vector{String})
    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
       if lens > 8
            skipbytes = max(0, skipbytes - 16)
            sorttwo!(load_bits.(UInt128, svec, skipbytes), svec)
            lens -= 16
        elseif lens > 4
            skipbytes = max(0, skipbytes - 8)
            sorttwo!(load_bits.(UInt64, svec, skipbytes), svec)
            lens -= 8
        else
            skipbytes = max(0, skipbytes - 4)
            sorttwo!(load_bits.(UInt32, svec, skipbytes), svec)
            lens -= 4
        end
    end
    svec
end

function radixsort_lsd24!(svec::Vector{String})
    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
        if lens > 16 && ceil(lens/24) < ceil(lens/16)
            skipbytes = max(0, skipbytes - 24)
            sorttwo!(load_bits.(Bits192, svec, skipbytes), svec)
            lens -= 24
        elseif lens > 8
        # if lens > 8
            skipbytes = max(0, skipbytes - 16)
            sorttwo!(load_bits.(UInt128, svec, skipbytes), svec)
            lens -= 16
        elseif lens > 4
            skipbytes = max(0, skipbytes - 8)
            sorttwo!(load_bits.(UInt64, svec, skipbytes), svec)
            lens -= 8
        else
            skipbytes = max(0, skipbytes - 4)
            sorttwo!(load_bits.(UInt32, svec, skipbytes), svec)
            lens -= 4
        end
    end
    svec
end

function radixsort_lsd32!(svec::Vector{String})
    # find the maximum string length
    lens = reduce((x,y) -> max(x,sizeof(y)),0, svec)
    skipbytes = lens
    while lens > 0
        if lens > 24
            skipbytes = max(0, skipbytes - 32)
            sorttwo!(load_bits.(Bits256, svec, skipbytes), svec)
            lens -= 32
        elseif lens > 16 && ceil(lens/24) < ceil(lens/16)
            skipbytes = max(0, skipbytes - 24)
            sorttwo!(load_bits.(Bits192, svec, skipbytes), svec)
            lens -= 24
        elseif lens > 8
        # if lens > 8
            skipbytes = max(0, skipbytes - 16)
            sorttwo!(load_bits.(UInt128, svec, skipbytes), svec)
            lens -= 16
        elseif lens > 4
            skipbytes = max(0, skipbytes - 8)
            sorttwo!(load_bits.(UInt64, svec, skipbytes), svec)
            lens -= 8
        else
            skipbytes = max(0, skipbytes - 4)
            sorttwo!(load_bits.(UInt32, svec, skipbytes), svec)
            lens -= 4
        end
    end
    svec
end

radixsort!(svec::Vector{String}) = radixsort!(UInt, svec::Vector{String})
radixsort!(::Type{T}, svec::Vector{String}) where T = radixsort_lsd!(svec)