using CairoMakie, Makie, GeoMakie
using YAXArrays, Zarr

# rechunked mesogeos cube
input = open_dataset("/Net/Groups/BGI/work_3/scratch/fgans/DeepCube/UC3Cube_rechunked2.zarr");

# plot extreme event
input_burnt = input[:burned_areas]
time = lookup(input_burnt, 3);
# subset around (20,40,2321)
c = input_burnt[x = 20 .. 20.1, y = 39.9 .. 40, time = time[2310] .. time[2330]]
lon = lookup(c, :x);
lat = lookup(c, :y);
time = lookup(c, 3);
data = permutedims(c.data[:,:,:], (1,3,2));
# there should be some non null data at data[:,11,:]

colmap = :bluesreds
n = 3;
g(x) = x;
alphas = [g(x) for x in range(0, 1, length = n)];
cmap_alpha = resample_cmap(colmap, n; alpha = alphas)

points3d = [Point3f(ix, iz, iy) for ix in lon, iz in 1:length(time), iy in lat];

fig = Figure();
ax = Axis3(fig[1, 1], 
    # perspectiveness = 0.5,
    azimuth = 6.64,
    elevation = 0.57, aspect = (1, 2, 1),
    xlabel = "Longitude", ylabel = "Time", zlabel = "Latitude");
meshscatter!(ax, vec(points3d); color = vec(data), 
    colorrange = (0,1),    
    colormap = cmap_alpha,
    marker=Rect3f(Vec3f(-0.5), Vec3f(1)),
    markersize=0.9,
    )
fig

