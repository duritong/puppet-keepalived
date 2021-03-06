# == Define: keepalived::lvs::virtual_server
#
# Configure a Linux Virtual Server with keepalived
#
# Work in progress, supports:
#   - single IP/port virtual servers
#   - TCP_CHECK healthchecks
#
# === Parameters
#
# Refer to keepalived's documentation to understand the behaviour
# of these parameters
#
# [*ip_address*]
#   Virtual server IP address.
#
# [*port*]
#   Virtual sever IP port.
#
# [*fwmark*]
#   Virtual Server firewall mark. (overrides ip_address and port)
#   Default: not set
#
# [*lb_algo*]
#   Must be one of rr, wrr, lc, wlc, lblc, sh, dh
#   Default: not set.
#
# [*delay_loop*]
#   Default: not set.
#
# [*protocol*]
#   Default: TCP
#
# [*lb_kind*]
#   Must be one of NAT, TUN, DR.
#   Default: NAT
#
# [*ha_suspend*]
#   Boolean.
#   Default: false => not set in config.
#
# [*alpha*]
#   Boolean.
#   Default: false => not set in config.
#
# [*omega*]
#   Boolean.
#   Default: false => not set in config.
#
# [*quorum*]
#   Integer.
#   Defaults to unset => does not appear in config.
#
# [*hysteresis*]
#   Integer.
#   Defaults to unset => does not appear in config.
#
# [*tcp_check*]
#   The TCP_CHECK to configure for real_servers.
#   Should be a hash containing these keys:
#     [*connect_timeout*]
#   Default: unset => no TCP_CHECK configured.
#
# [*real_server_options*]
#   One or more options to apply to all real_server blocks inside this
#   virtual_server.
#
#   Example:
#     real_server_options => {
#       inhibit_on_failure => true,
#       SMTP_CHECK => {
#         connect_timeout => 10
#         host => {
#           connect_ip => '127.0.0.1'
#         }
#       }
#     }
#
#   Default: unset => no default options
#
# [*sorry_server*]
#   The sorry_server to define
#   A hash with these keys:
#     [*ip_address*]
#     [*port*]
#
# [*sorry_server_inhibit*]
#   Boolean.
#   Default: false => not set in config.
#
# [*real_servers*]
#   The real servers to balance to.
#   An array of hashes.
#   Hash keys:
#     [*ip_address*]
#     [*port*]       (if ommitted the port defaults to the VIP port)
#
# [*collect_exported*]
#   Boolean. Automatically collect exported @@keepalived::lvs::real_servers
#   with a virtual_server equal to the name/title of this resource. This allows
#   you to easily export a real_server resource on each node in the pool.
#   Defaults to true => collect exported real_servers
#
define keepalived::lvs::virtual_server (
  Enum['rr', 'wrr', 'lc', 'wlc',
    'lblc', 'sh', 'dh']         $lb_algo,
  Optional[Stdlib::IP::Address] $ip_address           = undef,
  Optional[Variant[
    Integer[0,99999],
    String[1,5]]]               $port                 = undef,
  Optional[Pattern[/^[0-9]+$/]] $fwmark               = undef,
  Boolean                       $alpha                = false,
  Boolean                       $collect_exported     = true,
  Optional[Variant[
    Pattern[/^[0-9]+$/],
    Integer]]                   $delay_loop           = undef,
  Boolean                       $ha_suspend           = false,
  Optional[Variant[
    Pattern[/^[0-9]+$/],
    Integer]]                   $hysteresis           = undef,
  Enum['NAT','DR','TUN']        $lb_kind              = 'NAT',
  Boolean                       $omega                = false,
  Optional[Integer]             $persistence_timeout  = undef,
  Enum['TCP', 'UDP']            $protocol             = 'TCP',
  Optional[Variant[
    Pattern[/^[0-9]+$/],
    Integer]]                   $quorum               = undef,
  Optional[Array[Struct[{
    ip_address => Stdlib::IP::Address,
    port       => Optional[Variant[Integer,Pattern[/^[0-9]+$/]]],
  }]]]                          $real_servers         = undef,
  Optional[Struct[{
    ip_address => Stdlib::IP::Address,
    port       => Optional[Variant[Integer,Pattern[/^[0-9]+$/]]],
  }]]                           $sorry_server         = undef,
  Boolean                       $sorry_server_inhibit = false,
  Optional[Struct[{
    connect_timeout => Integer
  }]]                           $tcp_check            = undef,
  Hash                          $real_server_options  = {},
  Optional[String]              $virtualhost          = undef,
) {
  $_name = regsubst($name, '[:\/\n]', '')

  if ( ! $fwmark and ! $ip_address ) {
    fail('Require IP address if fwmark is not set')
  }

  if $tcp_check != undef {
    warning('the $tcp_check argument is deprecated in favor of
            $real_server_options')
  }

  concat::fragment { "keepalived.conf_lvs_virtual_server_${_name}":
    target  => "${::keepalived::config_dir}/keepalived.conf",
    content => template('keepalived/lvs_virtual_server.erb'),
    order   => "250-${_name}-000",
  }

  concat::fragment { "keepalived.conf_lvs_virtual_server_${_name}-footer":
    target  => "${::keepalived::config_dir}/keepalived.conf",
    content => "}\n",
    order   => "250-${_name}-zzz",
  }

  if $collect_exported {
    Keepalived::Lvs::Real_server {
      options => $real_server_options,
    }
    Keepalived::Lvs::Real_server <<| virtual_server == $_name |>>
  }
}
