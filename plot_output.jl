# initial code in to /Net/Groups/BGI/people/fgans/DeepCube/FinalESDCDEmo/
using CairoMakie, Makie, GeoMakie
using YAXArrays, Zarr
using Statistics
using PerceptualColourMaps
using HDF5

# output of moving windo demo
ds = open_dataset("/Net/Groups/BGI/people/fgans/DeepCube/FinalESDCdemo/output.zarr/")

preds = ("lst_night", "lst_day","dem", "lc_forest", "lc_grassland", "roads_distance")
units = ("Difference in temperature [Kelvin]","Difference in temperature [Kelvin]","Difference in elevation [m]", "Difference in forest cover [%]", "Difference in grass cover [%]", "Difference in distance to nearest road [km]")
possible_predictors = map(i->ds[Symbol(i)],preds);

if !isdir("./figs")
    mkdir("./figs")
end

# coastlines
fid = h5open("world_xm.h5", "r")
tmp = read(fid["world_10m"])
x1 = tmp["lon"];
y1 = tmp["lat"];

function myfig!(fig, lon, lat, data, q, units, pred)
    ax = GeoAxis(fig[1,1], limits=(extrema(lon), extrema(lat)))
    s = surface!(ax, lon, lat, data; 
        colorrange=(-maximum(abs.(q)), maximum(abs.(q))),
        colormap , #:bluesreds, #cmap("CBD2"),#
        shading = NoShading,
    )
    cl=lines!(ax, 
        # GeoMakie.coastlines(),
        x1,y1,
        color = :black, linewidth=0.85)
    # translate!(cl, 0, 0, 1000)
    Colorbar(fig[1,2], s, label = units)
    Label(fig[1, 1:end, Top()], "Difference in average $(pred) inside and outside burned areas", fontsize=18, padding=(0, 6, 8, 0))

    return(fig)
end

# for i in 1:(length(possible_predictors))
    fig = Figure(;size=(1200,600));
    c = possible_predictors[i]
    lon = lookup(c, :x)
    lat = lookup(c, :y)
    data = c.data[:,:];

    @show q = Statistics.quantile(filter(i->!ismissing(i) && !isnan(i), data),(0.1,0.5,0.9))

    fig = myfig!(fig, lon, lat, data, q, units[i], preds[i])
    save("./figs/$(preds[i]).png", fig)

    sc = c[x = 20.5 .. 23.5, y = 36 .. 38.5]
    slon = lookup(sc, :x)
    slat = lookup(sc, :y)
    sdata = sc.data[:,:];
    fig = Figure(;size=(500,500));
    fig = myfig!(fig, slon, slat, sdata, q, units[i], preds[i])
    save("./figs/$(preds[i])_zoom.png", fig)


# end

# sc = c[x = 19 .. 26, y = 36 .. 42]
# sc = c[x = 21 .. 24, y = 36 .. 38]

# figs save in /Net/Groups/BGI/scratch/mweynants/DeepCube/

# lazaro
i=1


n = 256
colormap = vcat(resample_cmap(:linear_kbc_5_95_c73_n256, n),
    resample_cmap(Reverse(:linear_kryw_5_100_c67_n256), n))

s = surface!(ax, lon, lat, data; 
    colorrange=(-maximum(abs.(q)), maximum(abs.(q))),
    highclip=:black,
    lowclip=:grey8,
    #colorscale = sc,
    colormap, nan_color=:grey80,
    shading=NoShading,
)
cl=lines!(ax, x1, y1, color = :black, linewidth=0.85)
translate!(cl, 0, 0, 1000)

Colorbar(fig[1,2], s, label = units[i])
Label(fig[1, 1:end, Top()], "Difference in average $(preds[i]) inside and outside burned areas", fontsize=24, padding=(0, 6, 8, 0))

ax.xgridcolor[] = colorant"transparent"
ax.ygridcolor[] = colorant"transparent"
ax.xticklabelsvisible = false
ax.yticklabelsvisible = false

fig
# HDF5.jl