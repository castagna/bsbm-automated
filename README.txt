Berlin SPARQL Benchmark Automated
---------------------------------

Berlin SPARQL Benchmark (BSBM) is a benchmark for comparing performances of an 
RDF store across different architectures or for comparing different RDF stores.

The aim of this project is to make as easy as possible for people to run the 
Berlin SPARQL Benchmark with Joseki [1], Fuseki [2] and (this has not been 
implemented yet) a local TDB [3]. Other RDF stores might be added in future.

You can simply run the bash script typing:

  ./bsbm.sh 

You need bash, Java, Ant, Maven, SVN, wget, etc., and I am not going to explain 
how to install/configure those. The script downloads all the necessary software 
pieces, it sets them up, it uses the BSBM to generate a test dataset and it 
runs the benchmark for you against Joseki/TDB and Fuseki/TDB.
Once finished, you can find the results in the /tmp/bsbm/results/ directory.

You can take a look at the script and, once you have run it a couple of 
times, I suggest you change the parameters at the beginning a start doing
some serious benchmarking, in particular:

  BSBM_SCALE_FACTOR=1000
  BSBM_NUM_QUERY_MIXES=128
  BSBM_CONCURRENT_CLIENTS=1

You might want to use tdbloader2 instead of tdbloader:

  TDB_LOADER=tdbloader2

I am not a bash "guru", I warned you! You can insult me or send me suggestion
how to improve the script. Suggestions are more welcome than insults. ;-)


Thanks
------

Kudos to Chris Bizer and Andreas Schultz for having written and shared the 
Berlin SPARQL Benchmark (BSBM) which although not perfect, as any benchmark, 
can brings a degree of objectivity and replicability in the world of RDF store 
performances. Kudos to Andy Seaborne too for TDB and Fuseki and the continuous 
effort towards improving them as well as their performances.     


Have fun with the BSBM and TDB/Fuseki!


                                                              -- Paolo Castagna


 [1] http://www.joseki.org/
 [2] http://openjena.org/wiki/Fuseki
 [3] https://github.com/afs/BSBM-Local
