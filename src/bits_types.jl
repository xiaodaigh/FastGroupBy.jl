import Base: >>, <<, &, and_int, lshr_int, shl_int, or_int, |, bswap,
            zero
import SortingAlgorithms: uint_mapping

primitive type  Bits24 24 end
primitive type  Bits192 192 end
primitive type  Bits256 256 end

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

# UInt16(x::Bits192) = unsafe_load(Ptr{UInt16}(pointer_from_objref(x)))

bswap(x::Bits192) = Base.bswap_int(x)

uint_mapping(::Base.Order.ForwardOrdering, x::Bits192) = x

zero(::Type{Bits192}) = Bits192(0)

Int(x::Bits192) = Base.Intrinsics.trunc_int(Int, x)

convert(::Type{UInt16}, x::Bits192) = Base.Intrinsics.trunc_int(UInt16, x)

# promote_rule(::Type{Bits192}, ::Type{Integer}) = Bits192
(&)(x::Bits192, y::UInt16) = UInt16(x) & y

#########################################################################
#Bits 256
#########################################################################
>>(x::Bits256, y) = Base.lshr_int(x, y)
<<(x::Bits256, y) = Base.shl_int(x, y)

(&)(x::Bits256, y::Bits256) = Base.and_int(x,y)
(|)(x::Bits256, y::Bits256) = Base.or_int(x,y)

function Bits256(x)
    # it loads from the end
    z = unsafe_load(Ptr{Bits256}(pointer_from_objref(x)))
    
    if sizeof(Bits256) > sizeof(x)
        lzx = leading_zeros(x)
        shift_n = sizeof(Bits256)*8 - sizeof(eltype(x))*8
        z = z << shift_n >> shift_n
    end
    z
end

const u1256_mask = Bits256(2^16-1)

mask16bit(::Type{Bits256}) = u1256_mask

function make_mask(::Type{Bits256})
    x = UInt(2)^(sizeof(UInt)*8) - 1

    yy = unsafe_load(Ptr{Bits256}(pointer_from_objref(x)))    
    for i = 2:3
        y = unsafe_load(Ptr{Bits256}(pointer_from_objref(x)))
        # get rid of zeros in front
        y = y << 8*(sizeof(Bits256) - sizeof(UInt)) >> (sizeof(Bits256) - sizeof(UInt))*8
        yy = (yy << 8*sizeof(UInt)) | y
    end
    yy
end

# UInt16(x::Bits256) = unsafe_load(Ptr{UInt16}(pointer_from_objref(x)))

bswap(x::Bits256) = Base.bswap_int(x)

uint_mapping(::Base.Order.ForwardOrdering, x::Bits256) = x

zero(::Type{Bits256}) = Bits256(0)

Int(x::Bits256) = Base.Intrinsics.trunc_int(Int, x)
UInt16(x::Bits256) = Base.Intrinsics.trunc_int(UInt16, x)

# promote_rule(::Type{Bits256}, ::Type{Integer}) = Bits256
(&)(x::Bits256, y::UInt16) = (&)(UInt16(x), y)