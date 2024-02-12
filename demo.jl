using YAXArrays, Zarr
using OnlineStats: Mean, value, fit!, nobs
using YAXArrays.Cubes: cubesize, formatbytes
#Open the time series cube
ds = open_dataset("/Net/Groups/BGI/work_3/scratch/fgans/DeepCube/UC3Cube_rechunked2.zarr");

ds.

#Select variables of interest
burned_area = ds.burned_areas;
preds = ("lst_night", "lst_day","dem", "lc_forest", "lc_grassland", "roads_distance")
possible_predictors = map(i->ds[Symbol(i)],preds);

#Total uncompressed data size:
formatbytes(sum(cubesize,(burned_area,possible_predictors...)))

indims_burnedarea = InDims(MovingWindow("x",3,3), MovingWindow("y",3,3), "Time", window_oob_value = 0.f0)
indims_predictors = map(possible_predictors) do p
    td = ndims(p) == 3 ? ("Time",) : ()
    InDims(MovingWindow("x",3,3), MovingWindow("y",3,3), td..., window_oob_value = 0.f0)
end

outdims = OutDims(
    Dim{:Variable}(collect(preds)), 
    outtype = Float32, 
    backend=:zarr,
    path = "./output.zarr", 
    overwrite=true
)

n_workers = 20
threads_per_worker = 16
#Get 20 workers with 32 cpus per worker
using ClusterManagers: SlurmManager
using Distributed
for i in 1:20
    Threads.@spawn begin
        addprocs(
            SlurmManager(1,fill(2.0,10)),
            partition="big",
            mem_per_cpu="16GB",
            time="00:30:00",
            cpus_per_task=16,
            exeflags=`--project=$(@__DIR__) -t 32 --heap-size-hint=8GB`
        )
    end
end

#Load code everywhere
@everywhere begin
    using YAXArrays, Zarr
    using OnlineStats: Mean, value, fit!, nobs
    include("windowfire.jl")
    Zarr.Blosc.set_num_threads(16)
end


mapCube(
    fire_boundaries_window!, 
    (burned_area, possible_predictors...);
    indims = (indims_burnedarea, indims_predictors...), 
    outdims = outdims,
    max_cache=2e9,
)

rmprocs(5)

using CairoMakie, Makie, GeoMakie
using YAXArrays, Zarr
ds = open_dataset("output.zarr/")
heatmap(ds.roads_distance,colormap=:bluesreds)


# ilon = 1000
# ilat = 1000
# data = burned_area.data[ilon:ilon+6,ilat:ilat+6,:]
# preds = map(possible_predictors) do p
#     if ndims(p)==2
#         p.data[ilon:ilon+6,ilat:ilat+6]
#     else
#         p.data[ilon:ilon+6,ilat:ilat+6,:]
#     end
# end
# @code_warntype fire_boundaries_window!(zeros(Union{Float32,Missing},5),data,preds[1],preds[2],preds[3],preds[4],preds[5])



