# -*- coding: utf-8 -*-
'''
Beacon to fire events at specific syslog messages. 

.. code-block:: yaml

'''

# Import Python libs
from __future__ import absolute_import
import os
import struct
import re
import logging

# Import salt libs
import salt.utils

__virtualname__ = 'syslog'
SYSLOG = '/var/log/syslog'
LOC_KEY = 'syslog.loc'

log = logging.getLogger(__name__)


def __virtual__():
    if os.path.isfile(SYSLOG):
        return __virtualname__
    return False


def _get_loc():
    '''
    return the active file location
    '''
    if LOC_KEY in __context__:
        return __context__[LOC_KEY]


def __validate__(config):
    '''
    Validate the beacon configuration
    '''
    # Configuration for syslog beacon should be a list of dicts
    if not isinstance(config, dict):
        return False, ('Configuration for syslog beacon must be a dictionary.')
    return True, 'Valid beacon configuration'


#TODO: match values should be returned in the event
def beacon(config):
    '''
    Read the syslog file and return match whole string

    .. code-block:: yaml

        beacons:
           syslog:
	      <tag>:
		regex: <pattern>	
    '''
    ret = []
    with salt.utils.fopen(SYSLOG, 'r') as fp_:
        loc = __context__.get(LOC_KEY, 0)
        if loc == 0:
            fp_.seek(0, 2)
            __context__[LOC_KEY] = fp_.tell()
            #__context__["cnt"] = 0
            return ret
	
        fp_.seek(0, 2)
        __context__[LOC_KEY] = fp_.tell()
        fp_.seek(loc)

        txt = fp_.read()
        
	'''
	cnt = __context__.get("cnt",0)
        if cnt >= 10:
	     event = {'tag': 'keepalive'}
             ret.append(event)
             cnt = 0
             __context__["cnt"] = cnt
        '''

        d = {}
        for tag in config:
	    if 'regex' not in config[tag]:
		continue
	    if len(config[tag]['regex']) < 1:
		continue
	    try:  
               d[tag] = re.compile(r'{0}'.format(config[tag]['regex']))
            except:
               event = {'tag': tag, 'match': 'no', 'raw': '', 'error': 'bad regex'}
               ret.append(event)

        for line in txt.splitlines():
            for tag, reg in d.items():
               try:
                  m = reg.match(line)
                  if m is not None:
                      event = {'tag': tag, 'match': 'yes', 'raw': line, 'match': m, error: ''}
		  else:
                      event = {'tag': tag, 'match': 'no', 'raw': '', error: 'match not found'}
	       except:	  
                  event = {'tag': tag, 'match': 'no', 'raw':'', 'error': 'bad match'}
	       ret.append(event)
        '''
        cnt += 1
        __context__["cnt"] = cnt
        '''
    return ret
