#!/usr/bin/env python

import sys
import os
import xml.etree.ElementTree as ET

def get_qmph(querymix):
    return querymix.find("qmph").text


scale_factors = []
systems_under_test = []
use_cases = []
clients = []

path = sys.argv[1]

flist = os.listdir(path)
sortedflist = sorted(flist)
for fname in sortedflist:
    if fname.endswith (".xml"):
        tokens = fname[:-4].rsplit("-")
        if ( not int(tokens[0]) in scale_factors ): scale_factors.append(int(tokens[0]))
        if ( not tokens[1] in systems_under_test ): systems_under_test.append(tokens[1])
        if ( not tokens[2] in use_cases ): use_cases.append(tokens[2])
        if ( not int(tokens[3]) in clients ): clients.append(int(tokens[3]))

scale_factors = sorted(scale_factors)
systems_under_test = sorted(systems_under_test)
use_cases = sorted(use_cases)
clients = sorted(clients)

right_margin = 12
width = 10

for use_case in use_cases:
    for scale_factor in scale_factors:
        print ""
        print "sf=" + str(scale_factor) + " uc=" + use_case
        print ("{sf:>{right_margin}}".format(sf="threads:", right_margin=right_margin)), 
        header = True
        for system_under_test in systems_under_test:
            if header:
                for num_client in clients:
                    print ("{num_client:>{width}}".format(num_client=num_client, width=width)), 
                print ""
                header = False
            print ("{sut:>{right_margin}}".format(sut=system_under_test +":", right_margin=right_margin)), 
            for num_client in clients:
                try:
                    querymix = ET.parse(path + "/" + str(scale_factor) + "-" + system_under_test + "-" + use_case + "-" + str(num_client) + ".xml").getroot().find("querymix")
                    qmph = float(get_qmph(querymix))
                except IOError:
                    qmph = "-"
                try:
                    print ("{qmph:>{width}.0f}".format(qmph=qmph, width=width)), 
                except ValueError:
                    print ("{qmph:>{width}}".format(qmph=qmph, width=width)), 
            print ""



