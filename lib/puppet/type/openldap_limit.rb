Puppet::Type.newtype(:openldap_limit) do
  @doc = 'Manages OpenLDAP limits'

  ensurable

  newparam(:name) do
    desc "The default namevar"
  end

  newparam(:target) do
    desc "The slapd.conf file"
  end

  newproperty(:who, :namevar => true) do
    desc "To whom the limit applies"
  end

  newparam(:suffix, :namevar => true) do
    desc "The suffix to which the limit applies"
  end

  def self.title_patterns
    [
      [
        /^((\S+)\s+.+\s+on\s+(.+))$/,
        [
          [ :name, lambda{|x| x} ],
          [ :who, lambda{|x| x} ],
          [ :suffix, lambda{|x| x} ]
        ]
      ],
      [
        /^(\{(\d+)\}(\S+)\s+.+on\s+(.+))$/,
        [
          [ :name, lambda{|x| x} ],
          [ :position, lambda{|x| x} ],
          [ :who, lambda{|x| x} ],
          [ :suffix, lambda{|x| x} ]
        ]
      ],
      [
        /(.*)/,
        [
          [ :name, lambda{|x| x } ]
        ]
      ]
    ]
  end

  newparam(:position) do
    desc "Where to place the new entry"
  end

  newproperty(:limit, :array_matching => :all) do
    desc "Limit rule."
    def insync?(is)
      is.sort == should.sort
    end
  end

  autorequire(:openldap_database) do
    [ value(:suffix) ]
  end

end
