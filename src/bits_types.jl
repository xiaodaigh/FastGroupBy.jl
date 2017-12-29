import Base: >>, <<, &, and_int, lshr_int, shl_int, or_int, |
primitive type  Bits24 24 end
primitive type  Bits192 192 end

>>(x::Bits24, y) = Base.lshr_int(x, y)
<<(x::Bits24, y) = Base.shl_int(x, y)

>>(x::Bits192, y) = Base.lshr_int(x, y)
<<(x::Bits192, y) = Base.shl_int(x, y)

(&)(x::Bits192, y::Bits192) = Base.and_int(x,y)
(|)(x::Bits192, y::Bits192) = Base.or_int(x,y)

function Bits192(x)
    # it loads from the end
    z = unsafe_load(Ptr{Bits192}(pointer_from_objref(x)))
    
    if sizeof(Bits192) > sizeof(x)
        lzx = leading_zeros(x)
        shift_n = sizeof(Bits192)*8 - sizeof(eltype(x))*8
        z = z << shift_n >> shift_n
    end
    z
end

const u192_mask = Bits192(2^16-1)

mask16bit(::Type{Bits192}) = u192_mask
mask16bit(::Type) = 0xffff

function make_mask(::Type{Bits192})
    x = UInt(2)^(sizeof(UInt)*8) - 1

    yy = unsafe_load(Ptr{Bits192}(pointer_from_objref(x)))    
    for i = 2:3
        y = unsafe_load(Ptr{Bits192}(pointer_from_objref(x)))
        # get rid of zeros in front
        y = y << 8*(sizeof(Bits192) - sizeof(UInt)) >> (sizeof(Bits192) - sizeof(UInt))*8
        yy = (yy << 8*sizeof(UInt)) | y
    end
    yy
end

UInt16(x::Bits192) = unsafe_load(Ptr{UInt16}(pointer_from_objref(x)))

# vsi = Bits192(35323424)
# j = 2
# T = Bits192
# mask = mask16bit(T)

# x = (vsi >> (j-1)*16) & mask

# pointer_from_objref(pointer_from_objref)

# UInt16((vsi >> (j-1)*16) & mask)

# Int(Base.bswap(UInt16((vsi >> (j-1)*16) & mask))) + 1

