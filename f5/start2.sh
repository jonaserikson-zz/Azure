#!/bin/bash
###########################################################################
##       ffff55555                                                       ##
##     ffffffff555555                                                    ##
##   fff      f5    55         Deployment Script Version 0.0.1           ##
##  ff    fffff     555                                                  ##
##  ff    fffff f555555                                                  ##
## fff       f  f5555555             Written By: EIS Consulting          ##
## f        ff  f5555555                                                 ##
## fff   ffff       f555             Date Created: 12/02/2015            ##
## fff    fff5555    555             Last Updated: 06/22/2016            ##
##  ff    fff 55555  55                                                  ##
##   f    fff  555   5       This script will licens and pre-configure a ##
##   f    fff       55       BIG-IP for use in Azure                     ##
##    ffffffff5555555                                                    ##
##       fffffff55                                                       ##
###########################################################################
###########################################################################
##                              Change Log                               ##
###########################################################################
## Version #     Name       #                    NOTES                   ##
###########################################################################
## 11/23/15#  Thomas Stanley#    Created base functionality              ##
###########################################################################
## 06/22/16#  Gregory Coward#    Modified for generic BEST deployment    ##
###########################################################################

### Parameter Legend  ###
## devicearr=0 #login password for the BIG-IP
## devicearr=1 #BYOL License key


## Build the arrays based on the semicolon delimited command line argument passed from json template.
IFS=';' read -ra devicearr <<< "$1"    

## Construct the blackbox.conf file using the arrays.
jsonfile= '{"bigip":{"application_name":"My Application","ntp_servers":"1.pool.ntp.org 2.pool.ntp.org","ssh_key_inject":"false","change_passwords":"false","license":{"basekey":"'${devicearr[1]}'"},"modules":{"auto_provision":"true","ltm":"nominal","afm":"nominal","asm":"nominal","apm":"nominal"},"network":{"provision":"false"}}}'

echo $jsonfile > /config/blackbox.conf