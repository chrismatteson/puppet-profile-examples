# This profile installs and manages IBM HTTP Server on a node.
#
class profile::websphere::ihs {

  $base_dir             = lookup('websphere::base_dir')
  $ihs_instance_name    = lookup('websphere::ihs_profile_name')
  $instance_base        = lookup('websphere::ihs_instance_base')

  $ihs_installer        = '/depot/middleware/products/multiplatform/ibm/websphere/was855/suppl'
  $package_name         = 'com.ibm.websphere.IHS.v85'
  $package_version      = '8.5.5000.20130514_1044'

  $http_user            = lookup('websphere::ihs_user')
  $http_group           = lookup('websphere::ihs_group')

  $http_port            = '9160'
  $admin_port           = '8008'

  $dmgr_host            = lookup('dmgr_fqdn')
  $dmgr_cell            = lookup('dmgr_cell_name')
  $dmgr_profile         = lookup('websphere::dmgr_profile_name')

  # Create the IHS user and group
  user { 'IHS Admin User':
    ensure => present,
    name   => $http_user,
    uid    => '7148',
    gid    => $http_group,
  }
  group { 'IHS Admin Group':
    ensure => present,
    name   => $http_group,
    gid    => '5860',
  }


  # Create an IHS instance
  websphere_application_server::ihs::instance { $ihs_instance_name:
    target            => $instance_base,
    package           => $package_name,
    version           => $package_version,
    repository        => "${ihs_installer}/repository.config",
    install_options   => "-properties user.ihs.httpPort=${http_port}",
    user              => $http_user,
    group             => $http_group,
    manage_user       => false,
    manage_group      => false,
    admin_username    => $http_user,
    admin_password    => $http_user,
    admin_listen_port => $admin_port,
  }

  # Create an IHS server
  websphere_application_server::ihs::server { $ihs_instance_name:
    node_name             => "${facts['hostname']}webnode",
    target                => $instance_base,
    plugin_base           => "${base_dir}/Plugin01",
    cell                  => $dmgr_cell,
    dmgr_host             => $dmgr_host,
    httpd_config          => "${instance_base}/conf/httpd.conf",
    httpd_config_template => 'profile/ihs/httpd.conf.erb',
    listen_port           => $http_port,
    server_listen_port    => $http_port,
    user                  => $http_user,
    group                 => $http_group,
    admin_username        => $http_user,
    admin_password        => $http_user,
    require               => Ibm_pkg['Plugins', 'websphere_plg_fixpack'],
  }

  # Fixpacks and plugins
  ibm_pkg { 'websphere_ihs_fixpack':
    ensure        => present,
    package       => 'com.ibm.websphere.IHS.v85',
    version       => '8.5.5006.20150529_0536',
    repository    => '/depot/middleware/products/multiplatform/ibm/websphere/was855/fixpacks/fp06/8.5.5-WS-WASSupplements/repository.config',
    target        => $instance_base,
    package_owner => $http_user,
    package_group => $http_group,
    require       => WebSphere_application_server::Ihs::Instance[$ihs_instance_name],
  }

  ibm_pkg { 'Plugins':
    ensure        => 'present',
    package       => 'com.ibm.websphere.PLG.v85',
    version       => '8.5.5000.20130514_1044',
    repository    => '/depot/middleware/products/multiplatform/ibm/websphere/was855/suppl/repository.config',
    target        => "${base_dir}/Plugin01",
    package_owner => $http_user,
    package_group => $http_group,
    require       => Websphere_application_server::Ihs::Instance[$ihs_instance_name],
  }

  ibm_pkg { 'websphere_plg_fixpack':
    ensure        => present,
    package       => 'com.ibm.websphere.PLG.v85',
    version       => '8.5.5006.20150529_0536',
    repository    => '/depot/middleware/products/multiplatform/ibm/websphere/was855/fixpacks/fp06/8.5.5-WS-WASSupplements/repository.config',
    target        => "${base_dir}/Plugin01",
    package_owner => $http_user,
    package_group => $http_group,
    require       => Ibm_pkg['Plugins'],
  }

}
