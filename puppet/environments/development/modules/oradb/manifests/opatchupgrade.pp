# == Define: oradb::opatchupgrade
#
# upgrades oracle opatch
#
#
define oradb::opatchupgrade(
  String $oracle_home               = undef,
  String $patch_file                = undef,
  Optional[Integer] $csi_number     = undef,
  Optional[String] $support_id      = undef,
  String $opversion                 = undef,
  String $user                      = lookup('oradb::user'),
  String $group                     = lookup('oradb::group'),
  String $download_dir              = lookup('oradb::download_dir'),
  String $puppet_download_mnt_point = lookup('oradb::module_mountpoint'),
){
  $execPath = lookup('oradb::exec_path')
  $patchDir = "${oracle_home}/OPatch"

  $supported_db_kernels = join( lookup('oradb::kernels'), '|')
  if ( $facts['kernel'] in $supported_db_kernels == false){
    fail("Unrecognized operating system, please use it on a ${supported_db_kernels} host")
  }

  # check the opatch version
  $installedVersion  = opatch_version($oracle_home)

  if $installedVersion == $opversion {
    $continue = false
  } else {
    notify {"oradb::opatchupgrade ${title} ${installedVersion} installed - performing upgrade":}
    $continue = true
  }

  if ( $continue ) {

    if ! defined(File["${download_dir}/${patch_file}"]) {
      file {"${download_dir}/${patch_file}":
        ensure => present,
        path   => "${download_dir}/${patch_file}",
        source => "${puppet_download_mnt_point}/${patch_file}",
        mode   => '0775',
        owner  => $user,
        group  => $group,
      }
    }

    case $facts['kernel'] {
      'Linux', 'SunOS': {
        file { $patchDir:
          ensure  => absent,
          recurse => true,
          force   => true,
        } ->
        exec { "extract opatch ${title} ${patch_file}":
          command   => "unzip -o ${download_dir}/${patch_file} -d ${oracle_home}",
          path      => $execPath,
          user      => $user,
          group     => $group,
          logoutput => false,
          require   => File["${download_dir}/${patch_file}"],
        }

        if ( $csi_number != undef and support_id != undef ) {
          exec { "exec emocmrsp ${title} ${opversion}":
            cwd       => $patchDir,
            command   => "${patchDir}/ocm/bin/emocmrsp -repeater NONE ${csi_number} ${support_id}",
            path      => $execPath,
            user      => $user,
            group     => $group,
            logoutput => true,
            require   => Exec["extract opatch ${patch_file}"],
          }
        } else {

          if ! defined(Package['expect']) {
            package { 'expect':
              ensure  => present,
            }
          }

          file { "${download_dir}/opatch_upgrade_${title}_${opversion}.ksh":
            ensure  => present,
            content => epp('oradb/ocm.rsp.epp', { 'patchDir' => $patchDir }),
            mode    => '0775',
            owner   => $user,
            group   => $group,
          }

          exec { "ksh ${download_dir}/opatch_upgrade_${title}_${opversion}.ksh":
            cwd       => $patchDir,
            path      => $execPath,
            user      => $user,
            group     => $group,
            logoutput => true,
            require   => [File["${download_dir}/opatch_upgrade_${title}_${opversion}.ksh"],
                          Exec["extract opatch ${title} ${patch_file}"],
                          Package['expect'],],
          }
        }

      }
      default: {
        fail('Unrecognized operating system')
      }
    }
  }
}
