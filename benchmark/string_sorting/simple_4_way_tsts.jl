if false
    srand(1);
    svec = rand(string.(Char.(97:97+5)),10);
    csvec = copy(svec)
    lo = 1;
    hi = length(svec);
    cmppos = 1;


  include("src/three_way_radix_quick_sort.jl")
  three_way_radix_qsort(svec)

  svec = String["f", "a", "a", "a", "c", "c", "d", "d", "b", "f"]
  p,q = 2,9
  pivotl = 'f'
  j,i = 9,10
end