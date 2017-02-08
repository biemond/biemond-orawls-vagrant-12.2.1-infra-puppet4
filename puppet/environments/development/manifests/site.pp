node 'jrf2admin2.example.com' {

  include os
  include java
  include orawls::weblogic
  include orautils
  include fmw
  include opatch

  include domains
  include nodemanager, startwls, userconfig

  include security
  include basic_config
  include fmw_config
  include datasources
  include server_tlog
  include virtual_hosts
  include workmanagers
  include file_persistence
  include jms
  include pack_domain
  include deployments

  Class['java'] -> Class['orawls::weblogic']

}

class os {

  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances)

  # exec { "create swap file":
  #   command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8192",
  #   creates => "/var/swap.1",
  # }

  # exec { "attach swap file":
  #   command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
  #   require => Exec["create swap file"],
  #   unless => "/sbin/swapon -s | grep /var/swap.1",
  # }

  # #add swap file entry to fstab
  # exec {"add swapfile entry to fstab":
  #   command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
  #   require => Exec["attach swap file"],
  #   user => root,
  #   unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  # }

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = oracle
  user { 'oracle' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/oracle",
    comment    => 'oracle user created by Puppet',
    managehome => true,
    require    => Group['dba'],
  }

  $install = [ 'binutils.x86_64','unzip.x86_64',
               'xorg-x11-xauth.x86_64','compat-libcap1.x86_64',
               'compat-libstdc++-33.x86_64','libaio-devel.x86_64']


  # package { $install:
  #   ensure  => present,
  # }

  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'oracle'  => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
               },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class java {
  require os

  $remove = ["java-1.7.0-openjdk.x86_64",
             "java-1.6.0-openjdk.x86_64" ]

  # package { $remove:
  #   ensure  => absent,
  # }

  include jdk7

  jdk7::install7{ 'jdk-8u65-linux-x64':
      version                     => "8u65" ,
      full_version                => "jdk1.8.0_65",
      alternatives_priority       => 18000,
      x64                         => true,
      download_dir                => "/var/tmp/install",
      urandom_java_fix            => true,
      rsa_key_size_fix            => true,
      cryptography_extension_file => "jce_policy-8.zip",
      source_path                 => "/software",
  }

}

class fmw{
  require os,java,orawls::weblogic
  $default_params = {}
  $fmw_installations = hiera('fmw_installations', {})
  create_resources('orawls::fmw',$fmw_installations, $default_params)
}

class opatch{
  require fmw,orawls::weblogic
  $default_params = {}
  $opatch_instances = hiera('opatch_instances', {})
  create_resources('orawls::opatch',$opatch_instances, $default_params)
}

class domains{
  require orawls::weblogic, opatch

  # orawls::utils::rcu{ "RCU_12c DEV":
  #   fmw_product                 => "adf",
  #   oracle_fmw_product_home_dir => "/opt/oracle/middleware12c/oracle_common",
  #   jdk_home_dir                => "/usr/java/latest",
  #   os_user                     => 'oracle',
  #   os_group                    => 'dba',
  #   download_dir                => "/var/tmp/install",
  #   rcu_action                  => 'create',
  #   rcu_jdbc_url                => "jdbc:oracle:thin:@wlsdb.example.com:1521/wlsrepos.example.com",
  #   rcu_database_url            => "wlsdb.example.com:1521:wlsrepos.example.com",
  #   rcu_sys_password            => 'Welcome01',
  #   rcu_prefix                  => 'DEV',
  #   rcu_password                => 'Welcome01',
  #   log_output                  => true,
  # }

  $default_params = {}
  $domain_instances = hiera('domain_instances', {})
  create_resources('orawls::domain',$domain_instances, $default_params)

  $wls_setting_instances = hiera('wls_setting_instances', {})
  create_resources('wls_setting',$wls_setting_instances, $default_params)

}

class nodemanager {
  require orawls::weblogic, domains

  $default_params = {}
  $nodemanager_instances = hiera('nodemanager_instances', {})
  create_resources('orawls::nodemanager',$nodemanager_instances, $default_params)

  # $domain_name  = hiera('domain_name')

  # orautils::nodemanagerautostart{"autostart weblogic":
  #   version                   => '1221',
  #   domain                    => $domain_name,
  #   domain_path               => "${domains_path}/${domain_name}",
  #   wl_home                   => hiera('wls_weblogic_home_dir'),
  #   user                      => hiera('wls_os_user'),
  #   jsse_enabled              => hiera('wls_jsse_enabled'             ,false),
  #   custom_trust              => hiera('wls_custom_trust'             ,false),
  #   trust_keystore_file       => hiera('wls_trust_keystore_file'      ,undef),
  #   trust_keystore_passphrase => hiera('wls_trust_keystore_passphrase',undef),
  # }

}

class startwls {
  require orawls::weblogic, domains,nodemanager

  $default_params = {}
  $control_instances = hiera('control_instances', {})
  create_resources('orawls::control',$control_instances, $default_params)
}

class userconfig{
  require orawls::weblogic, domains, nodemanager, startwls
  $default_params = {}
  $userconfig_instances = hiera('userconfig_instances', {})
  create_resources('orawls::storeuserconfig',$userconfig_instances, $default_params)
}


class security{
  require userconfig
  $default_params = {}
  $user_instances = hiera('user_instances', {})
  create_resources('wls_user',$user_instances, $default_params)

  $group_instances = hiera('group_instances', {})
  create_resources('wls_group',$group_instances, $default_params)

  $authentication_provider_instances = hiera('authentication_provider_instances', {})
  create_resources('wls_authentication_provider',$authentication_provider_instances, $default_params)
}

class basic_config{
  require security
  $default_params = {}

  $wls_domain_instances = hiera('wls_domain_instances', {})
  create_resources('wls_domain',$wls_domain_instances, $default_params)

  # subscribe on changes
  $wls_adminserver_instances = hiera('wls_adminserver_instances', {})
  create_resources('wls_adminserver',$wls_adminserver_instances, $default_params)

  $machines_instances = hiera('machines_instances', {})
  create_resources('wls_machine',$machines_instances, $default_params)

  $server_instances = hiera('server_instances', {})
  create_resources('wls_server',$server_instances, $default_params)

  $server_channel_instances = hiera('server_channel_instances', {})
  create_resources('wls_server_channel',$server_channel_instances, $default_params)

  $cluster_instances = hiera('cluster_instances', {})
  create_resources('wls_cluster',$cluster_instances, $default_params)

  $coherence_cluster_instances = hiera('coherence_cluster_instances', {})
  create_resources('wls_coherence_cluster',$coherence_cluster_instances, $default_params)

  $server_template_instances = hiera('server_template_instances', {})
  create_resources('wls_server_template',$server_template_instances, $default_params)

  $dynamic_cluster_instances = hiera('dynamic_cluster_instances', {})
  create_resources('wls_dynamic_cluster',$dynamic_cluster_instances, $default_params)

}

class fmw_config {
  require basic_config

  $default_params = {}

  $fmw_cluster_instances = hiera('fmw_cluster_instances', $default_params)
  create_resources('orawls::utils::fmwcluster',$fmw_cluster_instances, $default_params)

  $fmw_jrf_cluster_instances = hiera('fmw_jrf_cluster_instances', $default_params)
  create_resources('orawls::utils::fmwclusterjrf',$fmw_jrf_cluster_instances, $default_params)

  $fmwlogdir_instances = hiera('fmwlogdir_instances', {})
  create_resources('orawls::fmwlogdir',$fmwlogdir_instances, $default_params)

  $webtier_instances = hiera('webtier_instances', {})
  create_resources('orawls::utils::webtier',$webtier_instances, $default_params)
}

class datasources{
  require fmw_config
  $default_params = {}
  $datasource_instances = hiera('datasource_instances', {})
  create_resources('wls_datasource',$datasource_instances, $default_params)
}

class server_tlog{
  require datasources
  $default_params = {}
  $server_tlog_instances = hiera('server_tlog_instances', {})
  create_resources('wls_server_tlog',$server_tlog_instances, $default_params)
}

class virtual_hosts{
  require server_tlog
  $default_params = {}
  $virtual_host_instances = hiera('virtual_host_instances', {})
  create_resources('wls_virtual_host',$virtual_host_instances, $default_params)
}

class workmanagers{
  require virtual_hosts
  $default_params = {}

  $workmanager_constraint_instances = hiera('workmanager_constraint_instances', {})
  create_resources('wls_workmanager_constraint',$workmanager_constraint_instances, $default_params)

  $workmanager_instances = hiera('workmanager_instances', {})
  create_resources('wls_workmanager',$workmanager_instances, $default_params)
}

class file_persistence{
  require workmanagers

  $default_params = {}

  $file_persistence_folders = hiera('file_persistence_folders', {})
  create_resources('file',$file_persistence_folders, $default_params)

  $file_persistence_store_instances = hiera('file_persistence_store_instances', {})
  create_resources('wls_file_persistence_store',$file_persistence_store_instances, $default_params)
}

class jms{
  require file_persistence

  $default_params = {}
  $jmsserver_instances = hiera('jmsserver_instances', {})
  create_resources('wls_jmsserver',$jmsserver_instances, $default_params)

  $jms_module_instances = hiera('jms_module_instances', {})
  create_resources('wls_jms_module',$jms_module_instances, $default_params)

  $jms_subdeployment_instances = hiera('jms_subdeployment_instances', {})
  create_resources('wls_jms_subdeployment',$jms_subdeployment_instances, $default_params)

  $jms_quota_instances = hiera('jms_quota_instances', {})
  create_resources('wls_jms_quota',$jms_quota_instances, $default_params)

  $jms_connection_factory_instances = hiera('jms_connection_factory_instances', {})
  create_resources('wls_jms_connection_factory',$jms_connection_factory_instances, $default_params)

  $jms_queue_instances = hiera('jms_queue_instances', {})
  create_resources('wls_jms_queue',$jms_queue_instances, $default_params)

  $jms_topic_instances = hiera('jms_topic_instances', {})
  create_resources('wls_jms_topic',$jms_topic_instances, $default_params)

  $foreign_server_instances = hiera('foreign_server_instances', {})
  create_resources('wls_foreign_server',$foreign_server_instances, $default_params)

  $foreign_server_object_instances = hiera('foreign_server_object_instances', {})
  create_resources('wls_foreign_server_object',$foreign_server_object_instances, $default_params)

  $safagent_instances = hiera('safagent_instances', {})
  create_resources('wls_safagent',$safagent_instances, $default_params)

  $saf_remote_context_instances = hiera('saf_remote_context_instances', {})
  create_resources('wls_saf_remote_context',$saf_remote_context_instances, $default_params)

  $saf_error_handler_instances = hiera('saf_error_handler_instances', {})
  create_resources('wls_saf_error_handler',$saf_error_handler_instances, $default_params)

  $saf_imported_destination_instances = hiera('saf_imported_destination_instances', {})
  create_resources('wls_saf_imported_destination',$saf_imported_destination_instances, $default_params)

  $saf_imported_destination_object_instances = hiera('saf_imported_destination_object_instances', {})
  create_resources('wls_saf_imported_destination_object',$saf_imported_destination_object_instances, $default_params)
}

class pack_domain{
  require jms

  $default_params = {}
  $pack_domain_instances = hiera('pack_domain_instances', $default_params)
  create_resources('orawls::packdomain',$pack_domain_instances, $default_params)
}



class deployments{
  require pack_domain

  $default_params = {}
  $deployment_instances = hiera('deployment_instances', $default_params)
  create_resources('wls_deployment',$deployment_instances, $default_params)
}

