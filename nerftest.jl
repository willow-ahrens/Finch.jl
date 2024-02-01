using Finch

time = Tensor(SingleRLE(Pattern()), 10)
grid = Tensor(SparseRLE{Float32}(SparseRLE{Float32}(Dense(Element(0.0)))), 10, 10, 28)
out = Tensor(SparseList(Dense(Element(0.0))), 10, 28)

@finch_code begin
         for t=_
           if time[t]
             for i=realextent(0.0,1.0), j=realextent(0.0,1.0)
                 for c=_
                   out[c,t] += coalesce(grid[c,(t+j),(t+i)], 0) * d(i) * d(j)
                 end
             end
           end
         end
       end
