require 'tempfile'

Puppet::Type.type(:openldap_limit).provide(:olc) do

  # TODO: Use ruby bindings (can't find one that support IPC)

  defaultfor :osfamily => :debian, :osfamily => :redhat

  commands :slapcat => 'slapcat', :ldapmodify => 'ldapmodify'

  mk_resource_methods

  def self.instances
    # TODO: restict to bdb, hdb and globals
    i = []
    slapcat(
      '-b',
      'cn=config',
      '-H',
      'ldap:///???(olcLimits=*)'
    ).split("\n\n").collect do |paragraph|
      limit = nil
      suffix = nil
      who = nil
      rawlimit = nil
      paragraph.gsub("\n ", '').split("\n").collect do |line|
        case line
        when /^olcSuffix: /
          suffix = line.split(' ')[1]
        when /^olcLimits: /
          foo, pos, who, rawlimit = line.match(/^olcLimits:\s+(\{(\d+)\})?(\S+)\s+(.+)$/).captures
          limit = rawlimit.split(' ').sort
        end
        i << new(
          :name   => "#{who} on #{suffix}",
          :ensure => :present,
          :who    => who,
          :limit  => limit,
          :suffix => suffix,
          :position => pos
        )
      end
    end
    i
  end

  def self.prefetch(resources)
    limits = instances
    resources.keys.each do |name|
      if provider = limits.find{ |limit| limit.name == name }
        resources[name].provider = provider
      end
    end
  end

  def getDn(suffix)
    slapcat(
      '-b',
      'cn=config',
      '-H',
      "ldap:///???(olcSuffix=#{suffix})"
    ).split("\n").collect do |line|
      if line =~ /^dn: /
        return line.split(' ')[1]
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def initialize(value={})
    super(value)
    @property_flush={}
  end

  def lastPost(suffix)
    slapcat(
      '-b',
      'cn=config',
      '-H',
      "ldap:///???(olcSuffix=#{suffix})"
    ).split("\n").select{|line| line =~ /^olcLimits:/}.length
  end

  def create
    position = resource[:position] ? "{#{resource[:position]}}" : "{#{lastPost(resource[:suffix])}}"
    t = Tempfile.new('openldap_access')
    t << "dn: #{getDn(resource[:suffix])}\n"
    t << "add: olcLimits\n"
    t << "olcLimits: #{position}#{resource[:who]} #{resource[:limit].sort.join(' ')}\n"
    t.close
    Puppet.debug(IO.read t.path)
    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read t.path}\nError message: #{e.message}"
    end
  end

  def destroy
    t = Tempfile.new('openldap_limit')
    t << "dn: #{getDn(@property_hash[:suffix])}\n"
    t << "changetype: modify\n"
    t << "delete: olcLimits\n"
    if @property_hash[:position]
      t << "olcLimits: {#{@property_hash[:position]}}\n"
    else
      t << "olcLimits: #{resource[:who]} #{resource[:limit].sort.join(' ')}\n"
    end
    t.close
    Puppet.debug(IO.read t.path)
    #slapdd('-b', 'cn=config', '-l', t.path)
    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read t.path}\nError message: #{e.message}"
    end
  end

  def limit=(value)
    position = "{#{@property_hash[:position]}}" if @property_hash[:position]
    t = Tempfile.new('openldap_limit')
    t << "dn: #{getDn(@property_hash[:suffix])}\n"
    t << "changetype: modify\n"
    t << "delete: olcLimits\n"
    if @property_hash[:position]
      t << "olcLimits: {#{@property_hash[:position]}}\n"
    else
      t << "olcLimits: #{@property_hash[:who]} #{@property_hash[:limit].sort.join(' ')}\n"
    end
    t << "-\n"
    t << "add: olcLimits\n"
    t << "olcLimits: #{position}#{@property_hash[:who]} #{value.sort.join(' ')}\n"
    t.close
    Puppet.debug(IO.read t.path)
    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read t.path}\nError message: #{e.message}"
    end
  end
end
