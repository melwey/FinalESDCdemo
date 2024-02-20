# initial code in to /Net/Groups/BGI/people/fgans/DeepCube/FinalESDCDEmo/
using CairoMakie, Makie, GeoMakie
using YAXArrays, Zarr
using Statistics
using PerceptualColourMaps
import HDF5

# mesogeos data cube
ds = open_dataset("https://my-uc3-bucket.s3.gra.io.cloud.ovh.net/mesogeos.zarr");

preds = ("ndvi","lai")
units = ("NDVI","Leaf Area Index")
possible_predictors = map(i->ds[Symbol(i)],preds);

if !isdir("./figs")
    mkdir("./figs")
end

# coastlines
fid = HDF5.h5open("world_xm.h5", "r")
tmp = HDF5.read(fid["world_10m"])
x1 = tmp["lon"];
y1 = tmp["lat"];

# colormap
colormap_ndvi = resample_cmap(:YlGn_9,256);

function myfig!(fig,i,j, lon, lat, data, date, units)
    ax = GeoAxis(fig[i,j], limits=(extrema(lon), extrema(lat)), title = date)
    s = surface!(ax, lon, lat, data; 
        colorrange=(0,1),
        highclip=colormap[end],
        lowclip=:lightblue,
        colormap, 
        nan_color=:grey80,
        shading=NoShading,
    )
    # coastlines
    cl=lines!(ax, 
        x1,y1,
        color = :black, linewidth=0.85)
    translate!(cl, 0, 0, 1000)
    # remove gridlines
    ax.xgridcolor[] = colorant"transparent";
    ax.ygridcolor[] = colorant"transparent";
    ax.xticklabelsvisible = false;
    ax.yticklabelsvisible = false;
    # add colorbar
    if i==2 && j==2
        Colorbar(fig[1,3], s, label = units)
    end
    return(fig)
end

for i in 1#1:(length(possible_predictors))
    p = possible_predictors[i];
    if ndims(p) == 3
            c = p[x = 20.5 .. 23.5, y = 36 .. 38.5, time = At([Date("2021-01-15"), Date("2021-04-15"), Date("2021-07-15"), Date("2021-10-15")])]
        else
            c = p
    end
    lon = lookup(c, :x)
    lat = lookup(c, :y)
    tempo = lookup(c, :Ti)
    data = c.data[:,:,:];

    @show q = Statistics.quantile(filter(i->!ismissing(i) && !isnan(i), data),(0.10,0.5,0.90))#(0.1,0.5,0.9))
    
    fig = Figure(;size=(1200,600));

    for j in 1:length(tempo)
        row, col = fldmod1(j, 2)
        date = string(Date(tempo[j]))
        fig = myfig!(fig, row, col, lon, lat, data[:,:,j], date, units[i])
        # Label(fig[1, 1:end, Top()], "Difference in average $(preds[i]) inside and outside burned areas", fontsize=18, padding=(0, 6, 8, 0))
    end
    fig
    save("./figs/input_$(preds[i]).png", fig)

end
