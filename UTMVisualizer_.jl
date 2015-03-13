# Author: Youngjun Kim, youngjun@stanford.edu
# Date: 03/09/2015

module UTMVisualizer_

export UTMVisualizer, visInit, visUpdate, updateAnimation, saveAnimation


using Visualizer_
using Scenario_

using PyCall
using PyPlot

@pyimport matplotlib.animation as ani

import Visualizer_.visInit
import Visualizer_.visUpdate
import Visualizer_.updateAnimation
import Visualizer_.saveAnimation


type UTMVisualizer <: Visualizer

    fig::Union(Figure, Nothing)
    ax1::Union(PyObject, Nothing)

    artists::Union(Vector{PyObject}, Nothing)

    ims::Vector{Any}

    wait::Bool


    function UTMVisualizer(;wait = false)

        self = new()

        self.fig = nothing
        self.ax1 = nothing

        self.artists = nothing

        self.ims = {}

        self.wait = wait
        
        return self
    end
end


function visInit(vis::UTMVisualizer, sc::Scenario)

    if vis.fig == nothing
        fig = figure(facecolor = "white")

        ax1 = fig[:add_subplot](111)
        ax1[:set_aspect]("equal")
        ax1[:set_xlim](0, sc.x)
        ax1[:set_ylim](0, sc.y)
        ax1[:set_xticklabels]([])
        ax1[:set_yticklabels]([])
        ax1[:grid](true)
        ax1[:set_title]("UTM Simulation")

        vis.fig = fig
        vis.ax1 = ax1
    else
        fig = vis.fig
        ax1 = vis.ax1

        for artist in vis.artists
            artist[:set_visible](false)
        end
    end

    artists = PyObject[]
    

    planned_path = ax1[:plot]([sc.uav_start_loc[1], map(x -> x[1], sc.uav_waypoints), sc.uav_end_loc[1]], [sc.uav_start_loc[2], map(x -> x[2], sc.uav_waypoints), sc.uav_end_loc[2]], ".--", color = "0.7")
    append!(artists, planned_path)


    uav_start_loc = ax1[:plot](sc.uav_start_loc[1], sc.uav_start_loc[2], "k.")
    append!(artists, uav_start_loc)


    if sc.uav_localization == :radiolocation
        for (x, y) in sc.cell_towers
            cell_tower = ax1[:plot](x, y, "k^", markerfacecolor = "white")
            append!(artists, cell_tower)
        end
    end


    fig[:canvas][:draw]()

    vis.artists = artists

    return vis
end


function visUpdate(vis::UTMVisualizer, sc::Scenario)

    fig = vis.fig
    ax1 = vis.ax1


    text = vis.ax1[:text](0.5, -0.02, "$(int(sc.x))ft x $(int(sc.y))ft, seed: $(sc.seed)", horizontalalignment = "center", verticalalignment = "top", transform = vis.ax1[:transAxes])
    push!(vis.artists, text)


    uav_marker = ax1[:plot](sc.uav_start_loc[1], sc.uav_start_loc[2], "mo", markersize = 5. / min(sc.x, sc.y) * 5280)
    append!(vis.artists, uav_marker)


    fig[:canvas][:draw]()

    return vis
end


function visUpdate(vis::UTMVisualizer, sc::Scenario, state::ScenarioState, timestep::Int64)

    fig = vis.fig
    ax1 = vis.ax1


    text = vis.ax1[:text](0.5, -0.02, "timestep: $timestep", horizontalalignment = "center", verticalalignment = "top", transform = vis.ax1[:transAxes])
    push!(vis.artists, text)


    uav_path = ax1[:plot]([map(x -> x[1], state.uav_past_locs), state.uav_loc[1]], [map(x -> x[2], state.uav_past_locs), state.uav_loc[2]], "r")
    append!(vis.artists, uav_path)


    uav_marker = ax1[:plot](state.uav_loc[1], state.uav_loc[2], "mo", markersize = 5. / min(sc.x, sc.y) * 5280)
    append!(vis.artists, uav_marker)


    fig[:canvas][:draw]()

    return vis
end


function updateAnimation(vis::UTMVisualizer, timestep::Int64 = -1; bSaveFrame::Bool = false, filename::ASCIIString = "sim.png")

    append!(vis.ims, {vis.artists})

    if bSaveFrame
        if timestep == -1
            savefig(filename, transparent = false)
        else
            base, ext = splitext(filename)
            savefig(base * "_" * string(timestep) * "." * ext, transparent = false)
        end
    end

    if vis.wait
        readline()
    end
end


function saveAnimation(vis::UTMVisualizer; interval::Int64 = 1000, repeat::Bool = false, filename::ASCIIString = "sim.mp4")

    im_ani = ani.ArtistAnimation(vis.fig, vis.ims, interval = interval, repeat = repeat, repeat_delay = interval * 5)
    im_ani[:save](filename)

    if repeat || vis.wait
        readline()
    end
end


end

