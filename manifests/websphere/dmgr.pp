# This creates a DMGR profile
#
class profile::websphere::dmgr {

  ############################
  ### Gather required data ###
  ############################
  $instance_base    = lookup('websphere::was_instance_base')
  $profile_base     = lookup('websphere::was_profiles_base')
  validate_absolute_path([$instance_base, $profile_base])

  $dmgr_profile     = lookup('websphere::dmgr_profile_name')
  $cluster_name     = lookup('cluster_name')
  $dmgr_cell        = "${facts['hostname']}cell01"
  $dmgr_node        = "${facts['hostname']}CellManager01"

  # Create a DMGR profile in WebSphere
  websphere_application_server::profile::dmgr { $dmgr_profile:
    instance_base       => $instance_base,
    profile_base        => $profile_base,
    cell                => $dmgr_cell,
    node_name           => $dmgr_node,
    collect_nodes       => true,
    collect_web_servers => true,
    collect_jvm_logs    => true,
  }

  # Create a cluster
  websphere_application_server::cluster { $cluster_name:
    profile_base => $profile_base,
    dmgr_profile => $dmgr_profile,
    cell         => $dmgr_cell,
    require      => Websphere_application_server::Profile::Dmgr[$dmgr_profile],
  }

}
