@testset "continuous examples" begin
    @info "Testing Continuous Finch Examples"

    @testset "2D Box Search" begin
        # Load 2d Points 
        point = [Pinpoints2D[i,:] .+ 1e7 for i in 1:size(Pinpoints2D,1)]

        # Load 2d Box Query 
        query = [QueryBox2D[i,:] .+ 1e7 for i in 1:size(QueryBox2D,1)]
        answer = [48, 23, 18, 31, 31, 82, 13, 84, 0, 21]

        # Setting up Point Fiber
        shape = Float64(2e7)
        shape_id = length(point)
        point_x = (xy->xy[1]).(point)
        point_y = (xy->xy[2]).(point)
        point_id = collect(Int64, 1:length(point_y))
        point_ptr_x = [1,length(point_x)+1]
        point_ptr_y = collect(Int64, 1:length(point_y)+1)
        point_ptr_id = collect(Int64, 1:length(point_y)+1)
        Point = Tensor(SparseList{Float64}(SingleList{Float64}(SingleList{Int64}(Pattern(),
                                                              shape_id,
                                                              point_ptr_id,
                                                              point_id),
                                          shape,
                                          point_ptr_y,
                                          point_y),
                      shape,
                      point_ptr_x,
                      point_x))

        # Setting up Box Fiber 
        box_x_start = [query[1][1]]
        box_y_start = [query[1][2]]
        box_x_stop = [query[1][3]]
        box_y_stop = [query[1][4]]
        box_ptr_x = [1,2]
        box_ptr_y = [1,2]
        Box = Tensor(SingleRLE{Float64}(SingleRLE{Float64}(Pattern(),
                                          shape,
                                          box_ptr_y,
                                          box_y_start,
                                          box_y_stop),
                       shape,
                       box_ptr_x,
                       box_x_start,
                       box_x_stop))

        Output = Tensor(SparseByteMap{Int64}(Pattern(), shape_id))

        def = @finch_kernel mode=fastfinch function rangequery(Output, Box, Point)
             Output .= false 
             for x=_, y=_, id=_
                 Output[id] |= Box[y,x] && Point[id,y,x]
             end
        end
        eval(def)

        for i=1:length(query)
            box_x_start = [query[i][1]]
            box_y_start = [query[i][2]]
            box_x_stop = [query[i][3]]
            box_y_stop = [query[i][4]]
            box_ptr_x = [1,2]
            box_ptr_y = [1,2]
            Box = Tensor(SingleRLE{Float64}(SingleRLE{Float64}(Pattern(),
                                       shape,
                                       box_ptr_y,
                                       box_y_start,
                                       box_y_stop),
                    shape,
                    box_ptr_x,
                    box_x_start,
                    box_x_stop))

            Output = Tensor(SparseByteMap{Int64}(Pattern(), shape_id))
            rangequery(Output, Box, Point)

            count = Scalar(0)
            @finch begin
                for id=_
                    if Output[id]
                        count[] += 1
                    end
                end
            end

            @test count.val == answer[i]
        end
    end
end
