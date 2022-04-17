A = Fiber(Solid(I, HollowList(J, Block(m, 2, Π, Block(n, 2, Φ, Element(0.0))))))
@loop I J i j
    (y[i] += A[I, J, i, j] * x[j])

B = Ravel(1, 3)(Ravel(2, 4)(A))
C = Overlay(1, Π, 2)(Overlay(2, Φ, 4)(A))


@loop I J K i j k
    (C[i, j] += A[i, k] * B[k, j])

@loop I J K (
    (@loop i j C[i, j] += c[i, j] * Π[I, i] * Π[J, j])
    where 
    (@loop i j k c[i, j] += a[i, k] * b[k, j])
    where 
    (@loop i k a[i, k] = A[i, k] * Π[I, i] * Π[K, k])
    where 
    (@loop k j b[k, j] = B[k, j] * Π[K, k] * Π[J, j])
)

a = Fiber(Solid(I, Solid(K, Buffer(m, 2, Π, Buffer(k, 2, Π)))))
b = Fiber(Solid(K, Solid(J, Buffer(k, 2, Π, Buffer(n, 2, Π)))))
c = Fiber(Solid(I, Solid(J, Buffer(m, 2, Π, Buffer(n, 2, Π)))))
@loop I J K (
    (@loop i j C[i, j] += c[i, j])
    where 
    (@loop i j k c[i, j] += a[i, k] * b[k, j])
    where 
    (@loop i k a[i, k] = A[i, k])
    where 
    (@loop k j b[k, j] = B[k, j])
)

A' = Fiber(Solid(I, Solid(K, Buffer(m, 2, Π, Buffer(k, 2, Π)))))
B' = Fiber(Solid(K, Solid(J, Buffer(k, 2, Π, Buffer(n, 2, Π)))))
C' = Fiber(Solid(I, Solid(J, Buffer(m, 2, Π, Buffer(n, 2, Π)))))
@loop I J K (
    (C'[I, J] = c)
    where 
    (@reindex @loop i j k c[i, j] += a[i, k] * b[k, j])
    where 
    (a = A'[I, K])
    where 
    (b = B'[K, J])
)

@index @loop I J K (
    (@reindex @loop i j k C'[I, J][i, j] += A'[I, K][i, k] * B'[K, J][k, j])
)