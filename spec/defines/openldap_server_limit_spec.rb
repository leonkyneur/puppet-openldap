require 'spec_helper'

describe 'openldap::server::limit' do
  let(:title) { 'foo'}

  let :pre_condition do
    "class {'openldap::server':}"
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'when Class[openldap::server] is not declared' do
        let(:pre_condition) { }
        it { expect { is_expected.to compile }.to raise_error(/class ::openldap::server has not been evaluated/) }
      end

      context 'with composite namevar' do
        let(:title) {
          'users on dc=mydomain,dc=com'
        }
        let(:params) {
          {
            :limit => 'size=unlimited'
          }
        }
        it { is_expected.to compile.with_all_deps }
        it {
          skip {'Should work'}
          is_expected.to contain_openldap_limit('users on dc=mydomain,dc=com').that_requires('Openldap_database[dc=mydomain,dc=com]').with({
            :who   => 'users',
            :limit => 'size=unlimited',
          })
        }
      end
    end
  end
end
