#!/usr/bin/env python

from __future__ import with_statement
#from fabric.api import local
import yaml
import subprocess
import time

def main():
    try: 
	with open('/srv/pillar/top.sls','r') as top_:
		y_top = yaml.load(top_)     
    except Exception as e: 
	return 1

    if 'base' not in y_top:
        return 1

    d = {}

    for name in y_top['base']:
	k = 'any' if name == '*' else name
        d[k] = []
        for files in y_top['base'][name]:
            files = "/srv/pillar/"+files+".sls"
     	    try: 
               with open(files, 'r') as fp_:
                  y_proxy = yaml.load(fp_)
            except EnvironmentError:
                  return 1

            if 'proxy' not in y_proxy:
               d.pop(k,None)
            else:
               d[name].append(y_proxy['proxy']) 
    
    for proxy in d:
        s = '--proxyid={}'.format(proxy)
        try:
           subprocess.call(['salt-proxy',s,'-l','debug','-d'])
        except Exception as e:
           print "salt-proxy not started: {}".format(str(e))
           return 1 

    return 0

if __name__ == '__main__':
     main()
     #local("/bin/bash")




