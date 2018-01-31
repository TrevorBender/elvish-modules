# Proxy manipulation
# Diego Zamboni <diego@zzamboni.org>
# To use it, add the following to your rc.elv:
#
#   use proxy
#   proxy:host = "proxy.corpnet.com:8079"
#
# You can then manually enable/disable the proxy by calling proxy:set and proxy:unset
#
# If you want to enable automatic proxy switching, you need to define
# a check function and add the corresponding hook. For example:
# 
#   proxy:test = { and ?(test -f /etc/resolv.conf) ?(egrep -q '^(search|domain).*corpnet.com' /etc/resolv.conf) }
#   prompt_hooks:add-before-readline { proxy:autoset }

# Proxy host to used by default. Usual format: host:port
host = ""

# This function should return a true value when the proxy needs to be set, false otherwise
# By default it returns false, you should override it with code that performs a meaningful
# check for your needs.
test = { put $false }

# Whether to print notifications when setting/unsetting the proxy
notify = $true

# Whether autoset should be disabled (useful for temporarily stopping the automatic proxy setting)
disable_autoset = $false

# Check whether the proxy is set. We use $E:http_proxy for the check
fn is-set {
  not-eq $E:http_proxy ""
}

# Set the proxy variables to the given string. If no parameters are given but `$proxy:host` is set,
# then its value is used
fn set [@param]{
  proxyhost = $host
  if (> (count $param) 0) {
    proxyhost = $param[0]
  }
  if (not-eq $proxyhost "") {
    E:http_proxy = $host
    E:https_proxy = $host
  }
}

# Unset the proxy variables
fn unset {
  del E:http_proxy
  del E:https_proxy
}

# Disable auto-set and unset the proxy
fn disable {
  disable_autoset = $true
  unset
}

# Enable auto-set
fn enable {
  disable_autoset = $false
}

# Automatically set the proxy by running `proxy:test` and setting/unsetting depending
# on the result
fn autoset {
  if (not $disable_autoset) {
    if ($test) {
      if (and $host (not (eq $host ""))) {
        if (and $notify (not (is-set))) { echo (edit:styled "Setting proxy "$host blue) }
        set $host
      } else {
        fail "You need to set $proxy:host to the proxy to use"
      }
    } else {
      if (and $notify (is-set)) { echo (edit:styled "Unsetting proxy" blue) }
      unset
    }
  }
}

fn setup_autoset {
  edit:before-readline=[ $@edit:before-readline { autoset } ]
  edit:after-readline=[ $@edit:after-readline [cmd]{ autoset } ]
}
