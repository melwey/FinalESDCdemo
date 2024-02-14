# initial code in to /Net/Groups/BGI/people/fgans/DeepCube/FinalESDCDEmo/
using CairoMakie, Makie, GeoMakie
using YAXArrays, Zarr
using Statistics
using PerceptualColourMaps

# rechunked mesogeos cube
input = open_dataset("/Net/Groups/BGI/work_3/scratch/fgans/DeepCube/UC3Cube_rechunked2.zarr");
# output of moving windo demo
ds = open_dataset("/Net/Groups/BGI/people/fgans/DeepCube/FinalESDCDEmo/output.zarr/")

preds = ("lst_night", "lst_day","dem", "lc_forest", "lc_grassland", "roads_distance")
units = ("Temperature [Kelvin]","Temperature [Kelvin]","Elevation [m]", "Forest cover [%]", "Grass cover [%]", "Distance to nearest road [km]")
possible_predictors = map(i->ds[Symbol(i)],preds);

if !isdir("./figs")
    mkdir("./figs")
end

function myfig!(fig, lon, lat, data)
    ax = GeoAxis(fig[1,1], limits=(extrema(lon), extrema(lat)))
    s = surface!(ax, lon, lat, data; 
        colorrange=(-maximum(abs.(q)), maximum(abs.(q))),
        colormap = cmap("CBD2"),#:bluesreds, 
        # shading=`NoShading`,
    )
    cl=lines!(ax, GeoMakie.coastlines(), color = :black, linewidth=0.85)
    # translate!(cl, 0, 0, 1000)
    Colorbar(fig[1,2], s, label = units[i])
    Label(fig[1, 1:end, Top()], "Difference in average $(preds[i]) inside and outside burned areas", fontsize=18, padding=(0, 6, 8, 0))

    return(fig)
end

for i in 1:(length(possible_predictors))
    fig = Figure(;size=(1200,600));
    c = possible_predictors[i]
    lon = lookup(c, :x)
    lat = lookup(c, :y)
    data = c.data[:,:];

    @show q = Statistics.quantile(filter(i->!ismissing(i) && !isnan(i), data),(0.1,0.5,0.9))

    fig = myfig!(fig, lon, lat, data)
    save("./figs/$(preds[i]).png", fig)

    sc = c[x = 19 .. 26, y = 36 .. 42]
    slon = lookup(sc, :x)
    slat = lookup(sc, :y)
    sdata = sc.data[:,:];
    fig = Figure(;size=(500,500));
    fig = myfig!(fig, slon, slat, sdata)
    save("./figs/$(preds[i])_zoom.png", fig)


end

# sc = c[x = 19 .. 26, y = 36 .. 42]
# sc = c[x = 21 .. 24, y = 36 .. 38]


function myfig!(fig, lon, lat, data)
    ax = GeoAxis(fig[1,1], limits=(extrema(lon), extrema(lat)))
    s = surface!(ax, lon, lat, data; 
        colorrange=(-maximum(abs.(q)), maximum(abs.(q))),
        colormap = cmap("CBD2"),#:bluesreds, 
        # shading=`NoShading`,
    )
    cl=lines!(ax, GeoMakie.coastlines(), color = :black, linewidth=0.85)
    # translate!(cl, 0, 0, 1000)
    Colorbar(fig[1,2], s, label = units[i])
    Label(fig[1, 1:end, Top()], "Difference in average $(preds[i]) inside and outside burned areas", fontsize=24, padding=(0, 6, 8, 0))

    return(fig)
end

# figs save in /Net/Groups/BGI/scratch/mweynants/DeepCube/