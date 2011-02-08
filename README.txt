Berlin SPARQL Benchmark Automated
---------------------------------

Berlin SPARQL Benchmark (BSBM) is a benchmark for comparing performances 
of an RDF store across different architectures or for comparing different 
RDF stores.

The aim of this project is to make as easy as possible for people to run
the Berling SPARQL Benchmark with Joseki [1], Fuseki [2] and (this has 
not been implemented yet) a local TDB [3].

Simply run the bsbm.sh script, you need Java, Ant, Maven, SVN, wget, ...
and I am not going to explain how to install/configure those. What the 
script does is downloading all the necessary software pieces, setting them
up, use the BSBM to generate a test dataset and run the benchmark for you.
You can find the results in the /tmp/bsbm/results/ directory.

You can take a look at the script and, once you have run it a couple of 
times, I suggest you change the parameters at the beginning a start doing
some serious benchmarking, in particular:

  BSBM_SCALE_FACTOR=1000
  BSBM_NUM_QUERY_MIXES=128
  BSBM_CONCURRENT_CLIENTS=1

You might want to use tdbloader2 instead of tdbloader:

  TDB_LOADER=tdbloader2


Have fun!

                                                          -- Paolo Castagna

 [1] http://www.joseki.org/
 [2] http://openjena.org/wiki/Fuseki
 [3] https://github.com/afs/BSBM-Local

