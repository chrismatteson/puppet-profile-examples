# This contains the common settings and configurations for all WebSphere
# server types. It should be applied to all the WebSphere servers to lay
# down the common file structure, user accounts, groups, etc..
#
class profile::websphere::common {

  # Validate that we're running on a WebSphere node.
  if ($facts['role'] !~ /^websphere/) or ($facts['role'] == undef) {
    fail("This node either isn't a WebSphere node or hasn't been given a role. Found role: '${facts['role']}'")
  }

  ############################
  ### Gather required data ###
  ############################
  $base_dir          = lookup('websphere::base_dir')
  $instance_name     = lookup('websphere::was_instance_name')
  $instance_base     = lookup('websphere::was_instance_base')
  $profile_base      = lookup('websphere::was_profiles_base')
  validate_absolute_path([$base_dir, $instance_base, $profile_base])

  $was_user          = lookup('websphere::was_user')
  $was_group         = lookup('websphere::was_group')
  $was_user_home     = "/home/${was_user}"

  # Create a hash of the WAS package information.
  # This should really be stored in Hiera.
  $was_package = {
    'name'       => 'com.ibm.websphere.ND.v85',
    'version'    => '8.5.5000.20130514_1044',
    'repository' => '/depot/middleware/products/multiplatform/ibm/websphere/was855/nd/was/repository.config',
  }


  #######################################
  ### Start creating WAS dependencies ###
  #######################################

  # Manage the permissions of the base WebSphere directory.
  file { 'websphere base directory':
    ensure => directory,
    path   => $base_dir,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Manually manage the permissions of the WebSphere instance directory (because the WebSphere module does not).
  file { 'websphere instance base directory':
    ensure => directory,
    path   => "${base_dir}/${instance_name}",
    owner  => $was_user,
    group  => $was_group,
    mode   => '0755',
  }

  # Create and manage the WAS admin user.
  user { 'websphere user account':
    ensure => 'present',
    name   => $was_user,
    uid    => '6886',
    gid    => $was_group,
    home   => $was_user_home,
  }

  # Create and manage the WAS admin group.
  group { 'websphere group account':
    ensure => present,
    name   => $was_group,
    gid    => '5870',
  }

  # Install the IBM Installation Manager.
  class { 'ibm_installation_manager':
    source_dir => '/depot/middleware/products/multiplatform/ibm/websphere/was855/installmgr/rhel_x86_64/installmgr162',
    target     => '/opt/IBM/InstallationManager',
    options    => '-acceptLicense -log /tmp/installation_manager_log.log',
  }

  # Setup the basic WebSphere environment. Directories, files, etc...
  class { 'websphere_application_server':
    user         => $was_user,
    group        => $was_group,
    manage_user  => false,
    manage_group => false,
    base_dir     => $base_dir,
    require      => Class['ibm_installation_manager'],
  }

  # Anchor these classes into the webshere::common profile.
  contain ibm_installation_manager
  contain websphere_application_server

  #####################################
  ### Start installing WAS packages ###
  #####################################

  # Create a WebSphere instance.
  websphere_application_server::instance { $instance_name:
    target       => $instance_base,
    package      => $was_package['name'],
    version      => $was_package['version'],
    profile_base => $profile_base,
    repository   => $was_package['repository'],
    user         => $was_user,
    group        => $was_group,
  }

  # Install a Fix Pack.
  ibm_pkg { 'fixpack_fp06':
    ensure        => present,
    package       => $was_package['name'],
    version       => '8.5.5006.20150529_0536',
    repository    => '/depot/middleware/products/multiplatform/ibm/websphere/was855/fixpacks/fp06/8.5.5-WS-WAS-FP0000006/repository.config',
    target        => $instance_base,
    package_owner => $was_user,
    package_group => $was_group,
    require       => Websphere_application_server::Instance[$instance_name],
  }

  # Install the WebSphere Java packages.
  ibm_pkg { 'WebSphere85_Java':
    ensure        => present,
    package       => 'com.ibm.websphere.IBMJAVA.v71',
    version       => '7.1.3000.20150528_1959',
    repository    => '/depot/middleware/products/multiplatform/ibm/websphere/was855/fixpacks/fp06/7.1.3.0-WS-IBMWASJAVA/repository.config',
    target        => $instance_base,
    package_owner => $was_user,
    package_group => $was_group,
    require       => Ibm_pkg['fixpack_fp06'],
  }

  # Fix the permissions of the wasadmin home directory because sometimes
  # the server is built incorrectly before Puppet gets to it.
  exec { "Set permissions of ${was_user_home}":
    command   => "find ${was_user_home}/ \\( ! -user ${was_user} -or ! -group ${was_group} \\) -exec chown ${was_user}:${was_group} -c {} \\;",
    onlyif    => "find ${was_user_home}/ \\( ! -user ${was_user} -or ! -group ${was_group} \\) | grep '.*'",
    path      => $facts['path'],
    logoutput => true,
    loglevel  => 'info',
  }

}
