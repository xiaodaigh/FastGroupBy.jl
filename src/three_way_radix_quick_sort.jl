function maxlength(svec, lo = 1, hi = length(svec))
    if lo > hi 
        return -1
    end
    ml = length(svec[lo])
    for i = lo+1:hi
        ml = max(ml, length(svec[i]))
    end
    ml
end

const CHAR0 = UInt8(0)
code_unit0(str, pos) = sizeof(str) >= pos ? codeunit(str, pos) : CHAR0

# inspiration http://www.cs.princeton.edu/courses/archive/spring03/cs226/lectures/radix
function three_way_radix_qsort0!(svec, lo = 1, hi = length(svec), cmppos = 1)
    if hi <= lo
        # println("terminate")
        return
    elseif hi - lo == 1
        if svec[lo] > svec[hi]
            svec[lo], svec[hi] = svec[hi], svec[lo]
        end
        return
    elseif hi - lo < 256
        sort!(svec, lo, hi, InsertionSort, Base.Forward)
        return
    end

    #  pick a pivot 
    pivot = svec[hi]

    # cmppos the position of letter to compare

    # i is the lower cursor, j is the upper cursor
    # p, q is used to keep track of equal elements in 4 way partition
    i, p = lo-1, lo
    j, q = hi+1, hi
    
    pivotl = code_unit0(pivot, cmppos)

    # after this loop the data should have been partition 4 ways
    while i < j
        while true
            i += 1
            code_unit0(svec[i],cmppos) < pivotl || break
        end        
        while true            
            j -= 1
            pivotl < code_unit0(svec[j], cmppos) || break     
            
            if j == lo
                break;
            end
        end
        if i > j
            break;
        end
        # swap them now
        svec[i], svec[j] = svec[j], svec[i]
        if code_unit0(svec[i], cmppos) == pivotl
            svec[p], svec[i] = svec[i], svec[p]
            p += 1
        end
        if code_unit0(svec[j], cmppos) == pivotl        
            svec[q], svec[j] = svec[j], svec[q]
            q -= 1
        end        
    end

    # if all elements are equal on that position then sort again
    if p >= q
        # println("p >= q")
        if maxlength(svec, lo, hi) > cmppos
            three_way_radix_qsort0!(svec, lo, hi, cmppos + 1)
            return
        end
    end

    # @show svec
    # println(string(p:q),pivotl,string(j:i),"lo:Hi",string(lo,hi))
    
    if code_unit0(svec[i], cmppos) < pivotl 
        i += 1
    end

    for k = lo:p-1
        svec[k], svec[j] = svec[j], svec[k]
        j -= 1
    end

    for k = hi:-1:q+1
        svec[k], svec[i] = svec[i], svec[k]
        i += 1
    end

    # recursive sort

    # println("lessthan: ", lo,j,cmppos)
    three_way_radix_qsort0!(svec, lo, j, cmppos)
    

    if i == hi && code_unit0(svec[i], cmppos) == pivotl
        i += 1
    end
    if maxlength(svec, j+1, i-1) > cmppos
        # println("mid: ", j+1,i-1,cmppos+1)
        three_way_radix_qsort0!(svec, j+1, i-1, cmppos + 1)
    end
    
    # println("gt: ", i,hi,cmppos+1)
    three_way_radix_qsort0!(svec, i, hi, cmppos)
    
    return
end

function three_way_radix_qsort(svec, lo = 1, hi = length(svec), cmppos = 1)
    if hi <= lo
        # println("terminate")
        return svec
    end

    #  pick a pivot in the middle
    pivot = svec[hi]

    # cmppos the position of letter to compare

    # i is the lower cursor, j is the upper cursor
    # p, q is used to keep track of equal elements in 4 way partition
    i, p = lo-1, lo
    j, q = hi+1, hi
    
    if length(pivot) >= cmppos
        pivotl = pivot[cmppos]
    else 
        pivotl = Char(0)
    end
    # after this loop the data should have been partition 4 ways
    while i < j
        while true
            i += 1
            length(svec[i]) <= cmppos || svec[i][cmppos] < pivotl || break
        end        
        while true            
            j -= 1
            # println(string(svec[j],":",cmppos))
            if cmppos <= length(svec[j])
                pivotl < svec[j][cmppos] || break     
            else
                break
            end
            if j == lo
                break;
            end
        end
        if i > j
            break;
        end
        # swap them now
        svec[i], svec[j] = svec[j], svec[i]
        if length(svec[i]) >= cmppos && svec[i][cmppos] == pivotl
            svec[p], svec[i] = svec[i], svec[p]
            p += 1
        end
        if length(svec[j]) >= cmppos && svec[j][cmppos] == pivotl        
            svec[q], svec[j] = svec[j], svec[q]
            q -= 1
        end        
    end

    # if all elements are equal on that position then sort again
    if p >= q
        # println("p >= q")
        if maxlength(svec, j+1, i-1) > cmppos
            three_way_radix_qsort(svec, lo, hi, cmppos + 1)
        end
    end

    # @show svec
    # println(string(p:q),pivotl,string(j:i),"lo:Hi",string(lo,hi))
    
    if length(svec[i]) >= cmppos && svec[i][cmppos] < pivotl 
        i += 1
    end

    for k = lo:p-1
        svec[k], svec[j] = svec[j], svec[k]
        j -= 1
    end

    for k = hi:-1:q+1
        svec[k], svec[i] = svec[i], svec[k]
        i += 1
    end

    # recursive sort
    
    three_way_radix_qsort(svec, lo, j, cmppos)
    

    if i == hi && length(svec[i]) >= cmppos && svec[i][cmppos] == pivotl
        i += 1
    end
    if maxlength(svec, j+1, i-1) > cmppos
        three_way_radix_qsort(svec, j+1, i-1, cmppos + 1)
    end
    
    three_way_radix_qsort(svec, i, hi, cmppos)
    
    svec
end

