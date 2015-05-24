# Natural Language Processing
This is the source code for the entity linking project which is part of the natural language processing course at ETHZ. It is built using [Julia v0.3.6](http://julialang.org/).

## Installation
Make sure you have julia installed and can call `julia` from the command line. Clone this repository to a location on your computer, and browse to that location. Create a folder `data/` in the repository folder and place the following data files in that directory:
* `crosswikis-dict-preprocessed.gz`
* `query-data-dev-set.xml`
* `query-data-train-set.xml`

## Run
To run the application:

    julia Main.jl <algorithm> <query-file> [output-file]

Where the `algorithm` is either `tagme`, `naive` or `lda`. The `query-file` parameter should be the path to the XML file that has the queries. Optionally you can specify an output file to which the annotator will write its predictions in XML format.
