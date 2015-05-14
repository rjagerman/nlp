
# Checks if two tuples of ints overlap
overlaps(r1::(Int, Int), r2::(Int, Int)) =  max(r1[1], r2[1]) ≤ min(r1[2], r2[2])
