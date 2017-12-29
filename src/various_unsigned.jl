import Base: >>, <<, &, and_int, lshr_int, shl_int, or_int, |
primitive type  UInt24 24 end
primitive type  UInt192 192 end

>>(x::UInt24, y) = Base.lshr_int(x, y)
<<(x::UInt24, y) = Base.shl_int(x, y)

>>(x::UInt192, y) = Base.lshr_int(x, y)
<<(x::UInt192, y) = Base.shl_int(x, y)

(&)(x::UInt192, y::UInt192) = Base.and_int(x,y)
(|)(x::UInt192, y::UInt192) = Base.or_int(x,y)

function UInt192(x)
    # it loads from the end
    z = unsafe_load(Ptr{UInt192}(pointer_from_objref(x)))
    
    if sizeof(UInt192) > sizeof(x)
        lzx = leading_zeros(x)
        shift_n = sizeof(UInt192)*8 - sizeof(eltype(x))*8
        z = z << shift_n >> shift_n
    end
    z
end

const u192_mask = UInt192(2^16-1)

mask16bit(::Type{UInt192}) = u192_mask
mask16bit(::Type) = 0xffff

function make_mask(::Type{UInt192})
    x = UInt(2)^(sizeof(UInt)*8) - 1

    yy = unsafe_load(Ptr{UInt192}(pointer_from_objref(x)))    
    for i = 2:3
        y = unsafe_load(Ptr{UInt192}(pointer_from_objref(x)))
        # get rid of zeros in front
        y = y << 8*(sizeof(UInt192) - sizeof(UInt)) >> (sizeof(UInt192) - sizeof(UInt))*8
        yy = (yy << 8*sizeof(UInt)) | y
    end
    yy
end

UInt16(x::UInt192) = unsafe_load(Ptr{UInt16}(pointer_from_objref(x)))

# vsi = UInt192(35323424)
# j = 2
# T = UInt192
# mask = mask16bit(T)

# x = (vsi >> (j-1)*16) & mask

# pointer_from_objref(pointer_from_objref)

# UInt16((vsi >> (j-1)*16) & mask)

# Int(Base.bswap(UInt16((vsi >> (j-1)*16) & mask))) + 1

