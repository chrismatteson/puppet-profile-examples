# Class: tse_sqlserver
# ===========================
#
# Full description of class tse_sqlserver here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'tse_sqlserver':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class tse_sqlserver {
  reboot { 'afterdism':
    when    => pending,
    message => 'Rebooting after installing the .NET Framework 3.5 role',
  }

  mount_iso { 'C:\SQLServer2014-x64-ENU.iso':
    drive_letter => 'E',
    require      => Reboot['afterdism'],
  }

  service { 'wuauserv':
    ensure => 'running',
    enable => 'true',
  }

  package { 'dogtail.dotnet3.5sp1':
    ensure   => 'installed',
    provider => 'chocolatey',
    require  => Service['wuauserv'],
    notify   => Reboot['afterdism'],
  }

  sqlserver_instance { 'MSSQLSERVER': 
    ensure                => present,
    features              => [ 'SQL' ],
    source                => 'E:/',
    sql_sysadmin_accounts => [ 'vagrant' ],
    require               => Mount_Iso['C:\SQLServer2014-x64-ENU.iso'],
  }

}