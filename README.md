# Natural Language Processing
This is the source code for the entity linking project which is part of the natural language processing course at ETHZ. It is built using [Julia v0.3.6](http://julialang.org/).

## Installation
Make sure you have julia installed and can call `julia` from the command line. Clone this repository to a location on your computer, and browse to that location. Create a folder `cache/` in the repository folder. Download the `data.zip` file (1.5GB zipped, 6GB unzipped) and unzip it to the repository folder.

## Dependencies
This julia project has dependencies on several julia packages:
* `DataStructures`: Priority queue
* `Distances`: Cosine distance metric
* `Gumbo`: HTML parsing
* `GZip`: Streaming gzip files
* `Iterators`: Iterative mapping
* `JSON`: JSON parsing
* `LightXML`: Reading/writing XML files
* `Match`: Scala-like match/case statements
* `Requests`: HTTP requests

You can install these dependencies by running `julia Dependencies.jl` in the repository folder.

If you wish to train the LDA model yourself, you will also need [`vw`](https://github.com/JohnLangford/vowpal_wabbit/wiki), [`python`](https://www.python.org/) and the [`nltk`](http://www.nltk.org/) python package. Instructions can be found in the `scripts/vw-wikipedia.jl` file.

## Run
To run the application:

    julia Main.jl <algorithm> <query-file> [output-file]

Where the `algorithm` is either `tagme`, `naive` or `lda`. The `query-file` parameter should be the path to the XML file that has the queries. Optionally you can specify an output file to which the annotator will write its predictions in XML format.
