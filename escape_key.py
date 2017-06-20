#!/usr/local/bin/python2

import sys
import os.path
file=sys.argv[1]
os.path.isfile(file)
with open(file, 'r') as key:
    lines=key.read().replace('\n', '\\n')
print lines