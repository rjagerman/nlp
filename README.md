# Natural Language Processing
This is the source code for the entity linking project which is part of the natural language processing course at ETHZ. It is built using [Julia v0.3.6](http://julialang.org/).

## Installation
Make sure you have julia installed and can call `julia` from the command line. Clone this repository to a location on your computer, and browse to that location. Create a folder `data/` in the repository folder and place the following data files in that directory:
* `crosswikis-dict-preprocessed.gz`
* `query-data-dev-set.xml`
* `query-data-train-set.xml`

Also create a folder `cache/` in the repository folder. This will ensure that the code can cache results which will improve the performance for future invocations.

## Run
To run the application:

    julia Main.jl

Alternatively open a julia shell by calling `julia` and execute the following command:

    include("Main.jl")

