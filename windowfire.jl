myvalue(x::Mean) = nobs(x) > 0 ? value(x) : missing
missingfit!(s,p) = !ismissing(p) && fit!(s,p)
function process_event(last_event_start::Int,last_event_end::Int, predictors, footprint,burned_area, mean_inside, mean_outside)
    burned_area_view = view(burned_area,:,:,last_event_start:last_event_end)
    predictor_views = map(predictors) do p
        if ndims(p) == 3
            view(p,:,:,last_event_start:last_event_end)
        else
            p
        end
    end
    any!(!iszero,footprint, burned_area_view)
    foreach(predictor_views,mean_inside,mean_outside) do pv, mi,mo
        broadcast(pv,footprint) do pred, isinfootprint
            stat = isinfootprint ? mi : mo
            missingfit!(stat,pred)
        end
    end
end
function fire_boundaries_window!(output, burned_area, p1, p2, p3, p4, p5, p6)
    predictors = (p1,p2,p3,p4,p5,p6)
    ntime = size(burned_area,3)
    footprint = falses(7,7,1)
    is_fire_timestep(i) = any(!iszero,view(burned_area,:,:,i))
    itime = 1
    mean_inside = map(_->Mean(),predictors)
    mean_outside = map(_->Mean(),predictors)
    in_fire = false
    last_event_start = 0
    while itime <= ntime
        if is_fire_timestep(itime)
            in_fire || (last_event_start = itime)
            in_fire = true
        else
            in_fire && process_event(last_event_start,itime-1, predictors, footprint,burned_area, mean_inside, mean_outside)
            in_fire = false
        end
        itime = itime + 1
    end
    in_fire && process_event(last_event_start,ntime, predictors, footprint,mean_inside, mean_outside)
    output .= myvalue.(mean_inside) .- myvalue.(mean_outside)
end
