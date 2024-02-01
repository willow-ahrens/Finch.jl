using Finch

out = Tensor(Dense(Element(0)))
a = Tensor(SparseList(SparseList(Element(0))))
b = Tensor(SparseList(Element(0)))

code = @finch_code begin
        for c=_
          for i=_
            for k=_
              out[i] += a[k+i, c] * b[k] # When toeplitz is in inner dimension, unfurl doesn't meet the condition because of current virtual_size implementation.
            end
          end
        end
end

display(code)