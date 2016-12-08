# Creates a WebSphere Application Server
#
class profile::websphere::app_server {

  ############################
  ### Gather required data ###
  ############################
  $instance_base        = lookup('websphere::was_instance_base')
  $profile_base         = lookup('websphere::was_profiles_base')
  validate_absolute_path([$instance_base, $profile_base])

  $was_user             = lookup('websphere::was_user')
  $was_group            = lookup('websphere::was_group')

  $dmgr_profile         = lookup('websphere::dmgr_profile_name')
  $dmgr_host            = lookup('dmgr_fqdn')
  $dmgr_cell            = lookup('dmgr_cell_name')

  $app_profile_name     = lookup('websphere::app_profile_name')
  $cluster_name         = lookup('cluster_name')
  $cluster_member_name  = lookup('cluster_member_name')


  ############################################
  ### Create an Application Server profile ###
  ############################################

  ## Manage the application server profile
  websphere_application_server::profile::appserver { $app_profile_name:
    instance_base  => $instance_base,
    profile_base   => $profile_base,
    template_path  => "${instance_base}/profileTemplates/managed",
    dmgr_host      => $dmgr_host,
    cell           => $dmgr_cell,
    node_name      => "${facts['hostname']}Node01",
    manage_sdk     => true,
    sdk_name       => '1.7.1_64',
    manage_service => true,
    user           => $was_user,
    group          => $was_group,
    dmgr_port      => '8879',
  }

  # Export a cluster member node with my information.
  # The DMGR will automatically federate with this cluster member the next time that
  # Puppet runs on the DMGR.
  @@websphere_application_server::cluster::member { $cluster_member_name:
    ensure                           => 'present',
    dmgr_host                        => $dmgr_host,
    dmgr_profile                     => $dmgr_profile,
    profile_base                     => $profile_base,
    node_name                        => "${facts['hostname']}Node01",
    cluster                          => $cluster_name,
    cell                             => $dmgr_cell,
    cluster_member_profile           => $dmgr_profile, # This must be the DMGR profile!!!
    runas_user                       => $was_user,
    runas_group                      => $was_group,
    jvm_maximum_heap_size            => '512',
    jvm_verbose_mode_class           => true,
    jvm_verbose_garbage_collection   => true,
    total_transaction_timeout        => '120',
    client_inactivity_timeout        => '20',
    threadpool_webcontainer_max_size => '75',
  }

}
