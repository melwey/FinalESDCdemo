using CairoMakie, Makie, GeoMakie
using YAXArrays, Zarr

# rechunked mesogeos cube
input = open_dataset("/Net/Groups/BGI/work_3/scratch/fgans/DeepCube/UC3Cube_rechunked2.zarr");

# plot extreme event
input_burnt = input[:burned_areas]
tempo = lookup(input_burnt, 3)
# subset around (20,40,2321)
c = input_burnt[x = 20 .. 20.1, y = 39.9 .. 40, time = tempo[2310] .. tempo[2330]]

lon = lookup(c, :x);
lat = lookup(c, :y);
δlon = abs(lon[2] - lon[1])
δlat = abs(lat[2] - lat[1])
tempo_cut = lookup(c, :Ti);
data_cut = c.data[:,:,:]

colormap = [(:grey9, 0.02), (:orangered, 0.8)]

points3d = [Point3f(ix, iz, iy) for ix in lon, iz in 1:length(tempo_cut), iy in lat];
data_vec = [data_cut[ix, iy, iz] for (ix, i) in enumerate(lon), (iz, k) in enumerate(tempo_cut), (iy, j) in enumerate(lat)]

y_ticks_pos = [1,5,10,15,20]
ticks_time = string.(Date.(tempo_cut[y_ticks_pos]))

fig = Figure();
ax = Axis3(fig[1, 1], 
    perspectiveness = 0.5,
    azimuth = 6.64,
    elevation = 0.57, aspect = (1, 2, 1),
    xlabel = "Longitude", ylabel = "Time", zlabel = "Latitude");
meshscatter!(ax, points3d[:]; color = data_vec[:], 
    colorrange = (0,1),    
    colormap,
    marker=Rect3f(Vec3f(-0.5), Vec3f(1)),
    markersize=Vec3f(δlon - 0.15*δlon, 0.85, δlat -0.15δlat),
    transparency=true
    )
ax.yticks = (y_ticks_pos, ticks_time)
ax.xlabeloffset = 50
fig
save("fire_demo.png", fig)