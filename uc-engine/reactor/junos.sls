reachability_check_of_junos_device:
   local.junos.cli:
     - tgt: 'proxy01'
     - arg:
       - "show version"
