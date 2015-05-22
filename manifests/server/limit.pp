# See README.md for details.
define openldap::server::limit(
  $ensure   = undef,
  $position = undef,
  $who      = undef,
  $limit    = undef,
  $suffix   = undef,
) {

  if ! defined(Class['openldap::server']) {
    fail 'class ::openldap::server has not been evaluated'
  }

  if $::openldap::server::provider == 'augeas' {
    Class['openldap::server::install'] ->
    Openldap::Server::Limit[$title] ~>
    Class['openldap::server::service']
  } else {
    Class['openldap::server::service'] ->
    Openldap::Server::Limit[$title] ->
    Class['openldap::server']
  }

  if (is_array($limit)) {
    $limits = $limit
  } else {
    $limits = split($limit, ' ')
  }
  openldap_limit { "${who} on ${suffix}":
    ensure   => $ensure,
    position => $position,
    provider => $::openldap::server::provider,
    target   => $::openldap::server::conffile,
    who      => $who,
    limit    => $limits,
    suffix   => $suffix,
  }
}
