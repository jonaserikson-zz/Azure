#!/bin/bash
###########################################################################
##       ffff55555                                                       ##
##     fffff f555555                                                     ##
##   fff      f5    5          Blackbox Deployment Script Version 1.8.3  ##
##  ff    fffff     555                                                  ##
##  ff    fffff f555555                                                  ##
## fff       f     55555             Written By: F5 Networks             ##
## f        ff     55555                                                 ##
## fff   ffff      ..:55             Date Created: 10/31/2013            ##
## fff    fff5555 ..::,5             Last Updated: 06/01/2015            ##
##  ff    fff 555555,;;                                                  ##
##   f    fff  55555,;       This script is a modified version of the    ##
##   f    fff    55,55         OpenStack auto-configuration script       ##
##    ffffffff5555555       Written by John Gruber and George Watkins    ##
##       fffffff55                                                       ##
###########################################################################
###########################################################################
##                              Change Log                               ##
###########################################################################
## Version #     Name       #                    NOTES                   ##                  
###########################################################################
## 10/31/13#  John Gruber   # Created base functionality                 ##
###########################################################################
##   1.0   #  Ken Bocchino  # Modified to work for Blackbox              ##
##         # Thomas Stanley #                                            ##
###########################################################################
##   1.1   #  Ken Bocchino  # Corrected Space Issue	                 ##
###########################################################################
##  1.1.1  #  Ken Bocchino  # Increased wait time for mcpd               ##
###########################################################################
##   1.2   #  Ken Bocchino  # Added base key file pull	                 ##
###########################################################################
##   1.5   #  Ken Bocchino  # Added iApp update 	                 ##
###########################################################################
##   1.5.1 #  Ken Bocchino  # Corrected basekeyfile null issue           ##
##         #                # Corrected DHCP and added logic for Rome    ##
###########################################################################
##   1.7   #  Ken Bocchino  # Converted iApp input to full JSON          ##
###########################################################################
##   1.8   #  Ken Bocchino  # Added status and error messages for Rome   ##
###########################################################################
##   1.8.1 #  Ken Bocchino  # Added error handling                       ##
###########################################################################
##   1.8.2 #  Ken Bocchino  # Added error handling                       ##
###########################################################################
##   1.8.3 #  Ken Bocchino  # Updated iApp Deployment                    ##
###########################################################################

shopt -s extglob
export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin/"

# Logging settings
LOGGER_TAG="blackbox-init"
LOGGER_CMD="logger -t $LOGGER_TAG"

# Wait for process settings
STATUS_CHECK_RETRIES=60
STATUS_CHECK_INTERVAL=10

# Blackbox user-data settings
OS_USER_DATA_RETRIES=20
OS_USER_DATA_RETRY_INTERVAL=10
OS_USER_DATA_RETRY_MAX_TIME=300
OS_USER_DATA_PATH="/config/blackbox.conf"
OS_USER_DATA_TEMP_PATH="/config/formatted_blackbox.conf"
OS_USER_DATA_TMP_FILE="/config/iapp_temp"
OS_USER_DATA_STATUS_PATH="/config/blackbox.status"

# BIG-IP password settings
OS_CHANGE_PASSWORDS=false

# BIG-IP licensing settings
BIGIP_LICENSE_FILE="/config/bigip.license"
BIGIP_LICENSE_RETRIES=5
BIGIP_LICENSE_RETRY_INTERVAL=5

# BIG-IP module provisioning
BIGIP_PROVISIONING_ENABLED=true
BIGIP_AUTO_PROVISIONING_ENABLED=false

# TMM interfaces network settings
OS_DHCP_ENABLED=true
OS_DHCP_LEASE_FILE="/tmp/blackbox-dhcp.leases"
OS_DHCP_REQ_TIMEOUT=30
OS_VLAN_PREFIX="blackbox-network-"
OS_VLAN_DESCRIPTION="auto-added by blackbox-init"
OS_SELFIP_PREFIX="blackbox-dhcp-"
OS_SELFIP_ALLOW_SERVICE="none"
OS_SELFIP_DESCRIPTION="auto-added by blackbox-init"
OS_PROVISION_FILE="/tmp/blackbox-provision"

# CMI group add settings
CMI_RETRIES=180
CMI_RETRY_INTERVAL=10

# Regular expressions
LEVEL_REGEX='^(dedicated|minimum|nominal|none)$'
PW_REGEX='^\$[0-9][A-Za-z]?\$'
TMM_IF_REGEX='^1\.[0-9]$'
IP_REGEX='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
SELFIP_ALLOW_SERVICE_REGEX='^(all|default|none)$'


# insert tag and log
function log() {
  echo "$1" | eval "$LOGGER_CMD"
}

function set_status() {
  echo "$1" > $OS_USER_DATA_STATUS_PATH
}

function upcase() {
  echo "$1" | tr '[a-z]' '[A-Z]'
}

function get_json_value() {
  echo -n $(perl -MJSON -ne "\$value = decode_json(\$_)->$1; \
    \$value =~ s/([^a-zA-Z0-9])/\$1/g; print \$value" $2)
}

function get_user_data_value() {
  echo -n $(get_json_value $1 $OS_USER_DATA_TEMP_PATH)
}

function get_user_data_system_cmds() {
  echo -n $(perl -MJSON -ne "print join(';;', \
  @{decode_json(\$_)->{bigip}{system_cmds}})" $OS_USER_DATA_TEMP_PATH)
}

function get_user_data_iapps_hash() {
  echo -ne $(perl -MJSON -ne "print join('\n', \
  %{decode_json(\$_)->$1})" $OS_USER_DATA_TEMP_PATH)
}

function get_user_data_iapps_array() {
  echo -ne $(perl -MJSON -ne "@value = @{decode_json(\$_)->$1}; foreach (@value) {if(ref(\$_) eq 'ARRAY') {foreach (@\$_) {\$string .= '\\\"' . \$_ . '\\\"' . ',';}print '\"[' . substr(\$string, 0, -1) . ']\" ';} else {print '\\\"' . \$_ . '\\\"' . \" \";}}" $OS_USER_DATA_TEMP_PATH)
}

function generate_sha512_passwd_hash() {
  salt=$(openssl rand -base64 8)
  echo -n $(perl -e "print crypt(q[$1], \"\\\$6\\\$$salt\\\$\")")
}

function get_dhcp_server_address() {
  echo -n $(awk '/dhcp-server-identifier/ { print $3 }' \
    /var/lib/dhclient/dhclient.leases | tail -1 | tr -d ';')
}

# check state
function wait_status_active() {
  failed=0
  while true; do
   state_started=$(cat /var/prompt/ps1)

    if [[ $state_started == Active ]]; then
      log "detected system Active"
      return 0
    fi

    failed=$(($failed + 1))

    if [[ $failed -ge $STATUS_CHECK_RETRIES ]]; then
      log "System was not Active after $failed checks, quitting..."
      set_status "Failure: System was not Active after $failed checks"
      return 1
    fi

    log "System was not Active (check $failed/$STATUS_CHECK_RETRIES), retrying in $STATUS_CHECK_INTERVAL seconds..."
    sleep $STATUS_CHECK_INTERVAL
  done
}

# check if MCP is running
function wait_mcp_running() {
  failed=0

  while true; do
    mcp_started=$(bigstart_wb mcpd start)

    if [[ $mcp_started == released ]]; then
      # this will log an error when mcpd is not up
      tmsh -a show sys mcp-state field-fmt | grep -q running 

      if [[ $? == 0 ]]; then
        log "Successfully connected to mcpd..."
        return 0
      fi
    fi

    failed=$(($failed + 1))

    if [[ $failed -ge $STATUS_CHECK_RETRIES ]]; then
      log "Failed to connect to mcpd after $failed attempts, quitting..."
      set_status "Failure: Failed to connect to mcpd after $failed attempts"      
      return 1
    fi

    log "Could not connect to mcpd (attempt $failed/$STATUS_CHECK_RETRIES), retrying in $STATUS_CHECK_INTERVAL seconds..."
    sleep $STATUS_CHECK_INTERVAL
  done
}

# wait for tmm to start
function wait_tmm_started() {
  failed=0

  while true; do
    tmm_started=$(bigstart_wb tmm start)

    if [[ $tmm_started == released ]]; then
      log "detected tmm started"
      return 0
    fi

    failed=$(($failed + 1))

    if [[ $failed -ge $STATUS_CHECK_RETRIES ]]; then
      log "tmm was not started after $failed checks, quitting..."
      set_status "Failure: tmm was not started after $failed checks"  
      return 1
    fi

    log "tmm not started (check $failed/$STATUS_CHECK_RETRIES), retrying in $STATUS_CHECK_INTERVAL seconds..."
    sleep $STATUS_CHECK_INTERVAL
  done
}

# extract license from JSON data and license unit
function license_bigip() {
  host=$(get_user_data_value {bigip}{license}{host})
  basekey=$(get_user_data_value {bigip}{license}{basekey})
  basekeyfile=$(get_user_data_value {bigip}{license}{basekeyfile})  
    if [[ -n $basekeyfile ]]; then
   	    basekey=`cat $basekeyfile`
         shred -u -z $basekeyfile
    fi
  addkey=$(get_user_data_value {bigip}{license}{addkey})
  sed -ised -e 's/sleep\ 5/sleep\ 10/' /etc/init.d/mysql
  rm -f /etc/init.d/mysqlsed
  if [[ ! -s $BIGIP_LICENSE_FILE ]]; then
    if [[ -n $basekey ]]; then
      failed=0

      # if a host or add-on key is provided, append to license client command
      [[ -n $host ]] && host_cmd="--host $host"
      [[ -n $addkey ]] && addkey_cmd="--addkey $addkey"

      while true; do
        log "Licensing BIG-IP using license key..."
        SOAPLicenseClient $host_cmd --basekey $basekey $addkey_cmd 2>&1 | eval $LOGGER_CMD

        if [[ $? == 0 && -f $BIGIP_LICENSE_FILE ]]; then
          log "Successfully licensed BIG-IP using user-data from instance metadata..."
          return 0
        else
          failed=$(($failed + 1))

          if [[ $failed -ge $BIGIP_LICENSE_RETRIES ]]; then
            log "Failed to license BIG-IP after $failed attempts, quitting..."
            set_status "Failure: Failed to license BIG-IP after $failed attempts" 
            exit
            return 1
          fi

          log "Could not license BIG-IP (attempt #$failed/$BIGIP_LICENSE_RETRIES), retrying in $BIGIP_LICENSE_RETRY_INTERVAL seconds..."
          sleep $BIGIP_LICENSE_RETRY_INTERVAL
        fi
      done
    else
      log "No BIG-IP license key found..."
      set_status "Failure: No BIG-IP license key found" 
      exit
      return 1      
    fi
  else
    log "BIG-IP already licensed, skipping license activation..."
  fi
  unset basekey
}

# return list of modules supported by current platform
function get_supported_modules() {
  echo -n $(tmsh list sys provision one-line | awk '/^sys/ { print $3 }')
}

# retrieve enabled modules from BIG-IP license file
function get_licensed_modules() {
  if [[ -s $BIGIP_LICENSE_FILE ]]; then
    provisionable_modules=$(get_supported_modules)
    enabled_modules=$(awk '/^mod.*enabled/ { print $1 }' /config/bigip.license |
      sed 's/mod_//' | tr '\n' ' ')

    for module in $enabled_modules; do
      case $module in
        wo@(c|m)) module="wom" ;;
        wa?(m)) module="wam" ;;
        af@(m|w)) module="afm" ;;
        am) module="apm" ;;
      esac
      
      if [[ "$provisionable_modules" == *"$module"* ]]; then
        licensed_modules="$licensed_modules $module"
        log "Found license for $(upcase $module) module..."
      fi
    done
    
    echo "$licensed_modules"
  else 
    log "Could not locate valid BIG-IP license file, no licensed modules found..."
  fi
}

# provision BIG-IP software modules 
function provision_modules() {
  [[ -f $OS_PROVISION_FILE ]] && rm -f $OS_PROVISION_FILE
  # get list of licensed modules
  licensed_modules=$(get_licensed_modules)
  provisionable_modules=$(get_supported_modules)
  
  # if auto-provisioning enabled, obtained enabled modules list from license \
  # file
  auto_provision=$(get_user_data_value {bigip}{modules}{auto_provision})
  log "auto_provision userdata set to $auto_provision"
  [[ $BIGIP_AUTO_PROVISIONING_ENABLED == false ]] && auto_provision=false 
  log "auto_provision after check, set to $auto_provision"
    
  for module in $licensed_modules; do 
    level=$(get_user_data_value {bigip}{modules}{$module})
        
    if [[ "$provisionable_modules" == *"$module"* ]]; then
      if [[ ! $level =~ $LEVEL_REGEX ]]; then 
        if [[ $auto_provision == true ]]; then
          level=nominal
        else
          level=none
        fi
      fi
      
       echo -e "sys provision $module { level $level }" >> $OS_PROVISION_FILE
       #also write to base so when we come back up we don't then depro the modules
       echo -e "sys provision $module { level $level }" >> /config/bigip_base.conf
      

    fi     
  done
	#provision all at once
	tmsh load sys config merge file $OS_PROVISION_FILE &> /dev/null

	if [[ $? == 0 ]]; then
	log "Successfully provisioned `cat $OS_PROVISION_FILE`"
   	else
	log "Failed to provision , examine /var/log/ltm for more information..."
	set_status "Failure: Failed to provision" 
	fi  
 }

function change_passwords() {
  root_password=$(get_user_data_value {bigip}{root_password})
  admin_password=$(get_user_data_value {bigip}{admin_password})
  
  change_passwords=$OS_CHANGE_PASSWORDS
  [[ $change_passwords == true && \
    $(get_user_data_value {bigip}{change_passwords}) == false ]] && \
    change_passwords=false

  if [[ $change_passwords == true ]]; then
    for creds in root:$root_password admin:$admin_password; do
      user=$(cut -d ':' -f1 <<< $creds)
      password=$(cut -d ':' -f2 <<< $creds)

      if [[ -n $password ]]; then
        if [[ $password =~ $PW_REGEX ]]; then
          password_hash=$password
          log "Found hash for salted password, successfully changed $user password..."
        else
          password_hash=$(generate_sha512_passwd_hash "$password")
          log "Found plain text password and (against my better judgement) successfully changed $user password..."
        fi

        sed -e "/auth user $user/,/}/ s|\(encrypted-password \).*\$|\1\"$password_hash\"|" \
	        -i /config/bigip_user.conf
      else
        log "No $user password found in user-data, skipping..."
      fi
    done

    tmsh load sys config user-only 2>&1 | eval $LOGGER_CMD
  else
    log "Password changed have been disabled, skipping..."
  fi

}

function set_tmm_if_selfip() {
  tmm_if=$1
  address=$2
  netmask=$3
  router=$4
  
  unset dhcp_enabled selfip_prefix selfip_name selfip_description selfip_allow_service vlan_name
  
  if [[ $address =~ $IP_REGEX && $netmask =~ $IP_REGEX ]]; then
    dhcp_enabled=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{dhcp})
    vlan_name=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{vlan_name})
    selfip_prefix=$(get_user_data_value {bigip}{network}{selfip_prefix})
    selfip_name=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{selfip_name})
    selfip_description=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{selfip_description})
    selfip_allow_service=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{selfip_allow_service})
    
    [[ -z $selfip_prefix ]] && selfip_prefix=$OS_SELFIP_PREFIX
    [[ -z $selfip_name ]] && selfip_name="${selfip_prefix}${tmm_if}"
    [[ -z $selfip_description ]] && selfip_description=$OS_SELFIP_DESCRIPTION
    [[ -z $selfip_allow_service ]] && selfip_allow_service=$OS_SELFIP_ALLOW_SERVICE
    
    if [[ $dhcp_enabled == false ]]; then
      log "Configuring self IP $selfip_name on VLAN $vlan_name with static address $address/$netmask..."
    else
      log "Configuring self IP $selfip_name on VLAN $vlan_name with DHCP address $address/$netmask..."
    fi

    selfip_cmd="tmsh create net self $selfip_name address $address/$netmask allow-service $selfip_allow_service vlan $vlan_name traffic-group traffic-group-local-only address-source from-user description \"$selfip_description\""
    log "  $selfip_cmd"
    eval "$selfip_cmd 2>&1 | $LOGGER_CMD"
  fi
  
    #setup default route
    default_route=$(get_user_data_value {bigip}{network}{default_route})
    if [[ -z $default_route ]]; then
   	    default_route=$router  	    
	    if [[ -n $default_route ]]; then	    
		tmsh create net route default_ipv4 { gw $default_route network default }
		log "Setting default route to $default_route" 
	    fi
    fi
}

function set_tmm_if_vlan() {
  tmm_if=$1

  unset vlan_prefix vlan_name vlan_description vlan_tag tagged vlan_tag_cmd tagged_cmd

  if [[ $tmm_if =~ $TMM_IF_REGEX ]]; then
    vlan_prefix=$(get_user_data_value {bigip}{network}{vlan_prefix})
    vlan_name=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{vlan_name})
    vlan_description=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{vlan_description})
    vlan_tag=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{vlan_tag})
    tagged=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{tagged})


    [[ -z $vlan_prefix ]] && vlan_prefix=$OS_VLAN_PREFIX
    [[ -z $vlan_name ]] && vlan_name="${vlan_prefix}${tmm_if}"
    [[ -z $vlan_description ]] && vlan_description=$OS_VLAN_DESCRIPTION

    if [[ $tagged == true && tagged_cmd="{ tagged } " ]]; then
      if [[ $vlan_tag -ge 1 && $vlan_tag -le 4096 ]]; then
        vlan_tag_cmd=" tag $vlan_tag "
        log "Configuring VLAN $vlan_name with tag $vlan_tag on interface $tmm_if..."
      fi
    else
      log "Configuring VLAN $vlan_name on interface $tmm_if..."
    fi

    vlan_cmd="tmsh create net vlan $vlan_name interfaces add { $tmm_if $tagged_cmd}$vlan_tag_cmd description \"$vlan_description\""

    log "  $vlan_cmd"
    eval "$vlan_cmd 2>&1 | $LOGGER_CMD"
  fi
}

function dhcp_tmm_if() {
  [[ -f $OS_DHCP_LEASE_FILE ]] && rm -f $OS_DHCP_LEASE_FILE

  log "Issuing DHCP request on interface 1.${1:3}..."
  dhclient_cmd="dhclient -lf $OS_DHCP_LEASE_FILE -cf /dev/null -1 -T \
    $OS_DHCP_REQ_TIMEOUT -sf /bin/echo -R \
    subnet-mask,broadcast-address,routers $1"
  eval "$dhclient_cmd 2>&1 | sed -e '/^$/d' -e 's/^/  /' | $LOGGER_CMD"
  pkill dhclient

  if [[ -f $OS_DHCP_LEASE_FILE ]]; then 
    dhcp_offer=`awk 'BEGIN {
      FS="\n"
      RS="}"
    }
    /lease/ {
      for (i=1;i<=NF;i++) {
        if ($i ~ /interface/) {
          gsub(/[";]/,"",$i)
          sub(/eth/, "1.", $i)
          split($i,INT," ")
          interface=INT[2]
        }
        if ($i ~ /fixed/) {
          sub(/;/,"",$i)
          split($i,ADDRESS," ")
          address=ADDRESS[2]
        }
        if ($i ~ /mask/) {
          sub(/;/,"",$i)
          split($i,NETMASK, " ")
          netmask=NETMASK[3]
        }
        if ($i ~ /routers/) {
          sub(/;/,"",$i)
          split($i,ROUTE, " ")
          router=ROUTE[3]
        }        
      }

      print interface " " address " " netmask " " router
          
    }' $OS_DHCP_LEASE_FILE`


 
    rm -f $OS_DHCP_LEASE_FILE
    
    

    echo $dhcp_offer
  fi
}

function configure_tmm_ifs() {
  tmm_ifs=$(ip link sh | egrep '^[0-9]+: eth[1-9]' | cut -d ' ' -f2 | 
    tr -d  ':')
    
  dhcp_enabled_global=$OS_DHCP_ENABLED
  [[ $dhcp_enabled_global == true && \
    $(get_user_data_value {bigip}{network}{dhcp}) == false ]] && \
    dhcp_enabled_global=false
    
    
    
  if [[ $dhcp_enabled_global == true ]]; then
    # stop DHCP for management interface because only one dhclient process can run at a time
    log "Stopping DHCP client for management interface..."
    service dhclient stop  &> /dev/null
    sleep 1
  fi

  [[ $dhcp_enabled_global == false ]] &&
    log "DHCP disabled globally, will not auto-configure any interfaces..."

  for interface in $tmm_ifs; do
    tmm_if="1.${interface:3}"
    dhcp_enabled=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{dhcp})

    # setup VLAN
    tmsh list net vlan one-line | grep -q "interfaces { .*$1\.${interface:3}.* }"

    if [[ $? != 0 ]]; then
      set_tmm_if_vlan $tmm_if
    else  
      log "VLAN already configured on interface $tmm_if, skipping..."
    fi
      
    # setup self-IP
    vlan_name=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{vlan_name})
    [[ -z $vlan_name ]] && vlan_name="${vlan_prefix}${tmm_if}"
    tmsh list net self one-line | grep -q "vlan $vlan_name"
    
    if [[ $? != 0 ]]; then
      if [[ $dhcp_enabled_global == false || $dhcp_enabled == false ]]; then
        # DHCP is disabled, look for static address and configure it
        address=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{address})
        netmask=$(get_user_data_value {bigip}{network}{interfaces}{$tmm_if}{netmask})

        if [[ -n $address && -n $netmask ]]; then
          set_tmm_if_selfip $tmm_if $address $netmask
        else
          log "DHCP is disabled and no static address could be located for $tmm_if, skipping..."
        fi
      else
        set_tmm_if_selfip $(dhcp_tmm_if $interface)  
        sleep 2
      fi
    else
      log "Self IP already configured for interface $tmm_if, skipping..."
    fi
  done
  

  if [[ $dhcp_enabled_global == true ]]; then
    # restart DHCP for management interface
    log "Restarting DHCP client for management interface..."
    service dhclient restart &> /dev/null
    #tmsh modify sys db dhclient.mgmt { value disable }
  fi
  
    default_route=$(get_user_data_value {bigip}{network}{default_route})

    if [[ -n $default_route ]]; then
	tmsh create net route default_ipv4 { gw $default_route network default }
	log "Setting default route to $default_route" 
    fi
 
  
  log "Saving after configuring interfaces"
  tmsh save sys config | eval $LOGGER_CMD
}

function execute_system_cmd() {
  system_cmds=$(get_user_data_system_cmds)
  
  IFS=';;'
  for system_cmd in $system_cmds; do
    if [[ -n $system_cmd ]]; then
      log "Executing system command: $system_cmd..."
      eval "$system_cmd 2>&1 | sed -e '/^$/d' -e 's/^/  /' | $LOGGER_CMD"
    fi
  done
  unset IFS
}

function cmi_configuration() {
     log "Provisioning CMI..."
     # disable dhcp for mgmt - must be static for config sync to work
     tmsh modify sys global-settings mgmt-dhcp disabled
     
     #set global hostname and device name
     hostname=$(get_user_data_value {loadbalance}{device_hostname}).azuresecurity.com
     host=`tmsh list sys global-settings | grep hostname`
     if [[ $host == *$hostname* ]]; then
          log "We are correctly named."
     else
          log "Renaming device to $hostname."
          tmsh modify sys global-settings hostname $hostname
          tmsh mv cm device bigip1 $hostname
          sleep 10
     fi  
     tmsh save sys config | eval $LOGGER_CMD
     
     # get the internal ip address from JSON
     address=$(get_user_data_value {loadbalance}{device_address})
     
     # set the config sync ip to the self/mgmt address
     tmsh modify cm device $hostname configsync-ip $address
     tmsh save sys config | eval $LOGGER_CMD
     
     # find out if we are master
     master=$(get_user_data_value {loadbalance}{is_master})
     if [[ $master == "true" ]]; then
          device_group=`tmsh list cm device-group Sync`          
          if [[ -z $device_group ]]; then         
               # we don't have the Sync device group; configure one to include the local device
               log "Sync device group not found, let's create it."
               # create the device group
               device_group_cmd="tmsh create cm device-group Sync devices add { $hostname } type sync-failover network-failover disabled auto-sync enabled asm-sync enabled"
               log "  $device_group_cmd"
               eval "$device_group_cmd 2>&1 | $LOGGER_CMD"             
          else
               # device group already exists
               log "Sync device group found, returning to deployment."
          fi
     else
          # we're a slave, so use REST API to join us to the trust domain and device group          
          device_group=`tmsh list cm device-group Sync`          
          if [[ -z $device_group ]]; then
               master_hostname=$(get_user_data_value {loadbalance}{master_hostname}).azuresecurity.com
               master_ip=$(get_user_data_value {loadbalance}{master_address})
               master_user=admin
               master_password="$(get_user_data_value {loadbalance}{master_password})"
               
               slave_hostname=$(get_user_data_value {loadbalance}{device_hostname}).azuresecurity.com
               slave_address=$(get_user_data_value {loadbalance}{device_address})
               slave_user=admin
               slave_password="$(get_user_data_value {loadbalance}{device_password})"
               
               # need to wait until the startup script has finished on the master BIG-IP
               failed=0
               until [[ "$(curl -sk -u $master_user:$master_password -X POST -H "Content-type: application/json" https://$master_ip/mgmt/tm/util/unix-ls -d '{ "command":"run","utilCmdArgs":"/config/azuresecurity.sh" }' | grep -o "No such file or directory")" ]] || [[ $failed -eq $CMI_RETRIES ]]; do
                    failed=$(($failed + 1))
                    log "Master not yet ready, retrying in $CMI_RETRY_INTERVAL seconds"
                    sleep $CMI_RETRY_INTERVAL
               done
               
               if [[ $failed -ge $CMI_RETRIES ]]; then
                    log "Could not detect that the master is ready after $failed attempts, quitting..."
                    set_status "Failure: Could not detect that the master is ready after $failed attempts"
                    exit
               fi
               
               # add ourselves to the trust domain on the master
               if [[ -n $master_password && -n $slave_password ]]; then
                    log "Adding this WAF to the trust domain..."
                    # check that the master device is present in our local trust domain
                    failed=0
                    until [[ "$(curl -sk -u $slave_user:$slave_password -X GET -H "Content-type: application/json" https://localhost/mgmt/tm/cm/trust-domain/ | grep -o "$master_hostname")" ]] || [[ $failed -eq $CMI_RETRIES ]]; do
                         failed=$(($failed + 1))
                         curl -sk -u $master_user:$master_password -X POST -H "Content-type: application/json" https://$master_ip/mgmt/tm/cm/add-to-trust -d '{ "command":"run","name":"Root","caDevice":true,"device":"'"$slave_address"'","deviceName":"'"$slave_hostname"'","username":"'"$slave_user"'","password":"'"$slave_password"'" }'
                         log "Not yet joined to trust domain after $failed tries, retrying in $CMI_RETRY_INTERVAL seconds"
                         sleep $CMI_RETRY_INTERVAL
                    done
                    
                    if [[ $failed -ge $CMI_RETRIES ]]; then
                         log "Could not join the trust domain after $failed attempts, quitting..."
                         set_status "Failure: Could not join the trust domain after $failed attempts"
                         exit
                    fi
                    
                    # add ourselves to the Sync device group on the master
                    log "Adding this WAF to the device group..."
                    # check that our device is present in the Sync device group locally
                    failed=0
                    until [[ "$(curl -sk -u $slave_user:$slave_password -X GET -H "Content-type: application/json" https://localhost/mgmt/tm/cm/device-group/~Common~Sync/devices | grep -o "$slave_hostname")" ]] || [[ $failed -eq $CMI_RETRIES ]]; do
                         failed=$(($failed + 1))
                         curl -sk -u $master_user:$master_password -X POST -H "Content-type: application/json" https://$master_ip/mgmt/tm/cm/device-group/~Common~Sync/devices -d '{ "name":"'"$slave_hostname"'" }'
                         log "Not yet joined to device group after $failed tries, retrying in $CMI_RETRY_INTERVAL seconds"
                         sleep $CMI_RETRY_INTERVAL
                    done
                    
                    if [[ $failed -ge $CMI_RETRIES ]]; then
                         log "Could not join the device group after $failed attempts, quitting..."
                         set_status "Failure: Could not join the device group after $failed attempts"
                         exit
                    fi
                                                                    
                    # continue after both WAFs have synchronized
                    log "Synchronizing..."                  
                    # check that the Sync device group is synchronized locally
                    failed=0
                    until [[ "$(curl -sk -u $slave_user:$slave_password -X GET -H "Content-type: application/json" https://localhost/mgmt/tm/cm/sync-status/ | grep -o "Sync (In Sync): All devices in the device group are in sync")" ]] || [[ $failed -eq $CMI_RETRIES ]]; do
                         failed=$(($failed + 1))
                         # sync from the slave to the master for the datasync-global-dg device group
                         curl -sk -u $slave_user:$slave_password -X POST -H "Content-Type: application/json" https://localhost/mgmt/tm/cm -d '{ "command":"run","utilCmdArgs":"config-sync to-group datasync-global-dg" }'
                         # sync from the master to the slave for the Sync device group
                         curl -sk -u $master_user:$master_password -X POST -H "Content-Type: application/json" https://$master_ip/mgmt/tm/cm -d '{ "command":"run","utilCmdArgs":"config-sync to-group Sync" }'
                         log "Not in sync yet after $failed tries, retrying in $CMI_RETRY_INTERVAL seconds..."                              
                         sleep $CMI_RETRY_INTERVAL
                    done
                    
                    if [[ $failed -ge $CMI_RETRIES ]]; then
                         log "Could not synchronize the device group after $failed attempts, quitting..."
                         set_status "Failure: Could not synchronize the device group after $failed attempts"
                         exit
                    fi
                    
               else
                    log "No credentials found, returning to deployment."
               fi
               
          else
               log "Sync device group found, returning to deployment."
          fi
          
          log "CMI configuration successful, returning to deployment."
     fi
}

function datagroup_configuration() {
     address=$(get_user_data_value {loadbalance}{device_address})
     master=$(get_user_data_value {loadbalance}{is_master})
     applianceid=$(get_user_data_value {logging}{applianceid})
     # this data group tracks the unique GUID of the Azure VM
     applianceid_data_group=`tmsh list ltm data-group internal applianceid_datagroup`
     # this data group maintains a list of application services and their original deployment time
     appsvc_data_group=`tmsh list ltm data-group internal appsvc_datagroup`
     # this data group controls overwrite of the ASM policy
     appstatus_data_group=`tmsh list ltm data-group internal appstatus_datagroup`
     
     # Check to see if we are master
     if [[ $master == "true" ]]; then
          if [[ -z $applianceid_data_group ]]; then
               # create the data group and add master
               applianceid_data_group_cmd="tmsh create ltm data-group internal /Common/applianceid_datagroup type string records add { $address { data $applianceid }  }"
          else 
               # add master to the data group
               # this is for the case where a master has rejoined the cluster using the same IP
               applianceid_data_group_cmd="tmsh modify ltm data-group internal /Common/applianceid_datagroup records modify { $address { data $applianceid }  }"
          fi
          
          if [[ -z $appsvc_data_group ]]; then
               # create the data group and add master
               appsvc_data_group_cmd="tmsh create ltm data-group internal /Common/appsvc_datagroup type string"
               eval "$appsvc_data_group_cmd 2>&1 | $LOGGER_CMD"
          else 
               log "App service data group already exists."
          fi
          
          if [[ -z $appstatus_data_group ]]; then
               # create the data group and set status to 1
               appstatus_data_group_cmd="tmsh create ltm data-group internal /Common/appstatus_datagroup type string records add { status { data 1 } }"
               eval "$appstatus_data_group_cmd 2>&1 | $LOGGER_CMD"
          else
               # reset the status to 1 when we start a script run
               appstatus_data_group_cmd="tmsh modify ltm data-group internal /Common/appstatus_datagroup records modify { status { data 1 } }"
               eval "$appstatus_data_group_cmd 2>&1 | $LOGGER_CMD"
          fi
     else
          # add slave to the applianceid data group
          applianceid_data_group_cmd="tmsh modify ltm data-group internal /Common/applianceid_datagroup records add { $address { data $applianceid }  }"
     fi
     
     eval "$applianceid_data_group_cmd 2>&1 | $LOGGER_CMD"
     tmsh save sys config | eval $LOGGER_CMD
}

function get_application_service() {
	echo -n $(tmsh list sys application service recursive ${1}.app/${1} one-line | awk '/^sys/ { print $4 }')
}

iapp_configuration_download() {
	  rm -f $OS_USER_DATA_TMP_FILE
	  
	  log "Retrieving user-iApp-data from $1..."
	  curl -k -s -f --retry $OS_USER_DATA_RETRIES --retry-delay \
	    $OS_USER_DATA_RETRY_INTERVAL --retry-max-time $OS_USER_DATA_RETRY_MAX_TIME \
   	    -o $OS_USER_DATA_TMP_FILE $1
   	  
   	  if [[ $? == 0 ]]; then
   	  	tmsh load sys config merge file $OS_USER_DATA_TMP_FILE &> /dev/null
   	  	sleep 10
    	  else
	      log "Could not retrieve user-data after $OS_USER_DATA_RETRIES attempts, quitting..."
	      set_status "Failure: Could not retrieve user-data after $OS_USER_DATA_RETRIES attempts"
	      return 1
 	  fi
}

iapp_configuration() {
     apps=`tmsh list sys application service recursive one-line | awk '/^sys/ { print $4 }' | awk -F'/' '{print $2}'`
     log "Current application services: $apps"
     iapp_templates=$(get_user_data_iapps_hash {bigip}{iappconfig})
     for iapp_template in ${iapp_templates[@]}; do
          if [[ -n $iapp_template && $iapp_template != *"HASH"* ]]; then
               log "downloading iApp template $iapp_template"
               iapp_configuration_download $(get_user_data_value {bigip}{iappconfig}{\"$iapp_template\"}{template_location})
               deployments=$(get_user_data_iapps_hash {bigip}{iappconfig}{\"$iapp_template\"}{deployments})
               # first delete any existing deployments that are missing from the JSON
               for app in $apps; do
                    if echo $deployments | grep $app; then
                         log "The application service $app belongs."
                    else
                         log "Deleting spplication service $app."
                         command="delete sys application service ${app}.app/${app}"
                         tmsh -c "$command"
                         if [[ $? == 0 ]]; then
                              log "Successfully deleted the $app application service."
                              delete_appsvc_data_group_cmd="tmsh modify ltm data-group internal /Common/appsvc_datagroup records delete { $app }"
                              eval "$delete_appsvc_data_group_cmd 2>&1 | $LOGGER_CMD"
                              tmsh save sys config | eval $LOGGER_CMD
                         else
                              log "Unable to delete the $app application service"
                         fi                                                                         
                    fi
               done
               for deployment in ${deployments[@]}; do
                    if [[ -n $deployment && $deployment != *"HASH"* ]]; then
                         log "Deploying Application Service $deployment using iApp template $iapp_template"
                         
                         # create the string of variables from JSON, formatted for use with the create sys app service command
                         service=" traffic-group "
                         service+=$(get_user_data_value {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{\"traffic-group\"})
                         service+=" strict-updates "
                         service+=$(get_user_data_value {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{\"strict-updates\"})        
                         service+=" " 
                         variables=$(get_user_data_iapps_hash {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{variables})
                         if [[ -n $variables ]]; then
                              service+=" variables replace-all-with {"
                              for variable in ${variables[@]}; do
                                   value=$(get_user_data_value {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{variables}{\"$variable\"})
                                   if [[ -n $variable && -n $value && $value != *"ARRAY"* ]]; then
                                        service+=$variable
                                        service+=" { value \""
                                        service+=$value
                                        service+="\" } "
                                   fi     
                              done
                              service+=" } "
                         fi
                         service+=" tables replace-all-with { "
                         tables=$(get_user_data_iapps_hash {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{tables})
                         for table in ${tables[@]}; do
                              if [[ -n $table && $table != *"HASH"* ]]; then
                                   service+=$table
                                   service+=" { column-names { "
                                   service+=$(get_user_data_iapps_array {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{tables}{\"$table\"}{\"column-names\"})
                                   service+=" } rows { "
                                   rows=$(get_user_data_iapps_hash {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{tables}{\"$table\"}{\"rows\"})
                                   for row in ${rows[@]}; do
                                        if [[ -n $row && $row != *"ARRAY"* ]]; then
                                             service+="{ row { "
                                             rowdataarray=$(get_user_data_iapps_array {bigip}{iappconfig}{\"$iapp_template\"}{deployments}{\"$deployment\"}{tables}{\"$table\"}{rows}{\"$row\"})
                                             for rowdata in ${rowdataarray[@]}; do
                                                  service+=$rowdata
                                                  service+=" "
                                             done     
                                             service+=" }}"
                                        fi
                                   done
                                   service+=" } }"     
                              fi
                         done     
                         service+=" } "
                         
                         if [[ -n $(get_application_service ${deployment}) ]]; then
                              # set the app status to 0, so the iApp will not download a new ASM policy
                              appstatus_data_group_cmd="tmsh modify ltm data-group internal /Common/appstatus_datagroup records modify { status { data 0 } }"
                              eval "$appstatus_data_group_cmd 2>&1 | $LOGGER_CMD"
                              
                              # deployment already exists, update the application service but don't touch the time stamp data group
                              command="modify sys application service ${deployment}.app/${deployment} execute-action definition $service"
                              log "Application Service Already Exists; Updating Deployment - Last Message $iapp_status"
                              set_status "Application Service Already Exists; Updating Deployment - Last Message $iapp_status"
                         else
                              # new deployment, add it to the time stamp data group
                              add_appsvc_data_group_cmd="tmsh modify ltm data-group internal /Common/appsvc_datagroup records add { $deployment { data $(date +%s) }  }"
                              eval "$add_appsvc_data_group_cmd 2>&1 | $LOGGER_CMD"
                              tmsh save sys config | eval $LOGGER_CMD
                              
                              # create the application service
                              command="create sys application service ${deployment} template $iapp_template $service"
                         fi
                         
                         # run the iApp command
                         tmsh -c "$command"
                         iapp_status=$(cat $OS_USER_DATA_STATUS_PATH)
                         # check that the application service we just deployed is present; if not, report failure
                         if [[ -z $(get_application_service ${deployment}) ]]; then
                              # remove failed deployment from data group
                              delete_appsvc_data_group_cmd="tmsh modify ltm data-group internal /Common/appsvc_datagroup records delete { $deployment }"
                              eval "$delete_appsvc_data_group_cmd 2>&1 | $LOGGER_CMD"
                              tmsh save sys config | eval $LOGGER_CMD
                              
                              log "Application Service Deployment Failed - Last Message $iapp_status"
                              set_status "Failure: Application Service Deployment Failed - Last Message $iapp_status"
                              exit
                         else
                              log "Application Service Deployment Succeeded - Last Message $iapp_status"
                         fi 					
                    fi
               done
          fi
     done
     # set the app status to 1, so the iApp will download a new ASM policy when run outside of the startup script
     appstatus_data_group_cmd="tmsh modify ltm data-group internal /Common/appstatus_datagroup records modify { status { data 1 } }"
     eval "$appstatus_data_group_cmd 2>&1 | $LOGGER_CMD"
}

function main() {
  start=$(date +%s)
  log "Starting Blackbox auto-configuration..."
  set_status "In Progress: Starting Configuration"
    
    #ensure json format - remove new lines
    cat $OS_USER_DATA_PATH | sed 's/\t/ /g' | sed ':a;N;$!ba;s/\n/ /g'  > $OS_USER_DATA_TEMP_PATH
    
    # ensure that mcpd is started and alive before doing anything
    wait_mcp_running
    set_status "In Progress: Connected to system"

    if [[ $? == 0 ]]; then
      sleep 10
      tmsh save sys config | eval $LOGGER_CMD
            
      	network_provision=$(get_user_data_value {bigip}{network}{provision})
      	if [[ $network_provision != "false" ]]; then
          configure_tmm_ifs
          wait_tmm_started
        fi
        
        dns_servers=$(get_user_data_value {bigip}{name_servers})
	if [[ -n $dns_servers ]]; then
	  tmsh modify sys dns name-servers replace-all-with { $dns_servers }
 	  log "Setting dns servers to $dns_servers" 
 	fi
 	
 	#check for resolv.conf
 	resolvconf=`cat /etc/resolv.conf`
	if [[ $resolvconf == "search localdomain" ]]; then
          nameserver=`tmsh list sys dns name-servers  | awk 'BEGIN {RS=""}{gsub(/\n/,"",$0); print $6}'`
          echo -e "search localhost\nnameserver      $nameserver\noptions ndots:0" > /etc/resolv.conf
 	fi 	
 	  
 	ntp_servers=$(get_user_data_value {bigip}{ntp_servers})
	if [[ -n $ntp_servers ]]; then
	  tmsh modify sys ntp timezone UTC servers replace-all-with { $ntp_servers }
  	  log "Setting ntp servers to $ntp_servers" 
          sleep 10 
        fi
        
        tmsh save sys config | eval $LOGGER_CMD
        set_status "In Progress: Licensing"     	
        license_bigip
        set_status "In Progress: Licensing - OK" 
        set_status "In Progress: Provisioning" 
        provision_modules
        sleep 10
        wait_status_active
        status=$?
        selfip_check=`tmsh list net self one-line`
        if [[ $status == 1 || -z $selfip_check ]]; then
        	log "We need to reboot to complete deployment"
        	set_status "In Progress: Rebooting"
        	reboot
        	exit
        fi  
        set_status "In Progress: Provisioning - OK" 
        execute_system_cmd

      wait_mcp_running
      # wait for stuff to restart
      sleep 10
      wait_mcp_running
      wait_tmm_started
      log "Changing db settings..."
      tmsh modify sys db configsync.allowmanagement value enable | eval $LOGGER_CMD
      tmsh modify sys global-settings gui-setup disabled | eval $LOGGER_CMD
      
      set_status "In Progress: CMI"      
      #cmi_configuration      
      set_status "In Progress: CMI - OK"
      
      set_status "In Progress: Configuring Data Groups"
      #datagroup_configuration
      set_status "In Progress: Configuring Data Groups OK"
      
      #if [[ $master == "true" ]]; then
      #     set_status "In Progress: Configuring Applications"     
      #     iapp_configuration           
      #     set_status "In Progress: Configuring Applications - OK"
      #else 
      #    log "We are a slave, nothing left to do."
      #fi
      
      sleep 10      
      tmsh save sys config | eval $LOGGER_CMD 
      fi

  finish=$(date +%s)
  log "Completed BlackBox auto-configuration in $(($finish-$start)) seconds..."
  set_status "OK"
  
  # remove startup script
  currentscript=$0
  set_status "Shredding ${currentscript}" 
  shred -u -z ${currentscript}
  
  set_status "OK"
  exit
}

# immediately background script to prevent blocking of MCP from starting
main &