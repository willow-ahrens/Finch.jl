@testset "merges" begin

    formats = [
        (;a = (;format = (z) -> @fiber(d(sl(e(z)))), proto = [follow, walk]),),
        (;a = (;format = (z) -> @fiber(d(sl(e(z)))), proto = [follow, fastwalk]),),
        (;a = (;format = (z) -> @fiber(d(sl(e(z)))), proto = [follow, gallop]),),
        (;a = (;format = (z) -> @fiber(d(sm(e(z)))), proto = [follow, walk]),),
        (;a = (;format = (z) -> @fiber(d(sm(e(z)))), proto = [follow, gallop]),),
        (;a = (;format = (z) -> @fiber(d(sc{1}(e(z)))), proto = [follow, walk]),),
        (;a = (;format = (z) -> @fiber(sc{2}(e(z))), proto = [walk, walk]),),
        (;a = (;format = (z) -> @fiber(d(sh{1}(e(z)))), proto = [follow, walk]),),
        (;a = (;format = (z) -> @fiber(sh{2}(e(z))), proto = [walk, walk]),),
    ]

    datasets = [
        (;a = (;default = 0.0, data = fill(0, 5, 5), ),),
        (;a = (;default = 0.0, data = fill(1, 5, 5), ),),
        (;a = (;default = 0.0, data = [
            0.0 0.1 0.0 0.0 0.0;
            0.0 0.8 0.0 0.0 0.0;
            0.0 0.2 0.1 0.0 0.0;
            0.4 0.0 0.3 0.5 0.2;
            0.0 0.4 0.8 0.1 0.5],)),
        (;a = (;default = 0.0, data = [
            0.0 0.0 0.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0;
            0.0 0.4 0.0 0.0 0.0],)),
        (;a = (;default = 0.0, data = [
            0.0 0.0 0.0 0.0 0.0;
            0.2 0.2 0.0 0.0 0.0;
            0.0 0.0 0.2 0.7 0.0;
            0.0 0.0 0.0 0.0 0.1;
            0.0 0.0 0.0 0.0 0.0],)),
    ]

    @testset "diagmask" begin
        for format in formats
            for dataset in datasets
                a = dropdefaults!(format.a.format(dataset.a.default), dataset.a.data)
                @testset "$(summary(a))[::$(format.a.proto[1]), ::$(format.a.proto[2])]" begin
                    b = @fiber(sc{2}(e(dataset.a.default)))
                    @finch @loop i j b[i, j] = a[i::(format.a.proto[1]), j::(format.a.proto[2])] * diagmask[i, j]
                    refdata = [dataset.a.data[i, j] * (j == i) for (i, j) in product(axes(dataset.a.data)...)]
                    ref = dropdefaults!(@fiber(sc{2}(e(dataset.a.default))), refdata)
                    @test isstructequal(b, ref)
                end
            end
        end
    end

    @testset "lotrimask" begin
        for format in formats
            for dataset in datasets
                a = dropdefaults!(format.a.format(dataset.a.default), dataset.a.data)
                @testset "$(summary(a))[::$(format.a.proto[1]), ::$(format.a.proto[2])]" begin
                    b = @fiber(sc{2}(e(dataset.a.default)))
                    @finch @loop i j b[i, j] = a[i::(format.a.proto[1]), j::(format.a.proto[2])] * lotrimask[i, j]
                    refdata = [dataset.a.data[i, j] * (j <= i) for (i, j) in product(axes(dataset.a.data)...)]
                    ref = dropdefaults!(@fiber(sc{2}(e(dataset.a.default))), refdata)
                    @test isstructequal(b, ref)
                end
            end
        end
    end

    @testset "uptrimask" begin
        for format in formats
            for dataset in datasets
                a = dropdefaults!(format.a.format(dataset.a.default), dataset.a.data)
                @testset "$(summary(a))[::$(format.a.proto[1]), ::$(format.a.proto[2])]" begin
                    b = @fiber(sc{2}(e(dataset.a.default)))
                    @finch @loop i j b[i, j] = a[i::(format.a.proto[1]), j::(format.a.proto[2])] * uptrimask[i, j]
                    refdata = [dataset.a.data[i, j] * (j >= i) for (i, j) in product(axes(dataset.a.data)...)]
                    ref = dropdefaults!(@fiber(sc{2}(e(dataset.a.default))), refdata)
                    @test isstructequal(b, ref)
                end
            end
        end
    end

    @testset "bandmask" begin
        for format in formats
            for dataset in datasets
                a = dropdefaults!(format.a.format(dataset.a.default), dataset.a.data)
                @testset "$(summary(a))[::$(format.a.proto[1]), ::$(format.a.proto[2])]" begin
                    b = @fiber(sc{2}(e(dataset.a.default)))
                    @finch @loop i j b[i, j] = a[i::(format.a.proto[1]), j::(format.a.proto[2])] * bandmask[i - 1, i + 1, j]
                    refdata = [dataset.a.data[i, j] * (i - 1 <= j <= i + 1) for (i, j) in product(axes(dataset.a.data)...)]
                    ref = dropdefaults!(@fiber(sc{2}(e(dataset.a.default))), refdata)
                    @test isstructequal(b, ref)
                end
            end
        end
    end
end