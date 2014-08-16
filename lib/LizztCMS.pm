# LizztCMS content management system
# Copyright (C) Utrop A/S Portu media & Communications 2008-2013
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package LizztCMS;

use Moose;

# If LizztCMS isn't in its own directory then stuff will not load properly,
# so make sure that we are before we do anything else.
BEGIN
{
    use FindBin;
    chdir($FindBin::RealBin.'/..');
}

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst 5.90000 qw/
	Authentication
	ConfigLoader
	Static::Simple
	Session
	Session::State::Cookie
	Session::Store::FastMmap
    Cache
				/; # Newline separated so it's easy to read
use LizztCMS::HelperModules::I18N;
use LizztCMS::HelperModules::Log;
use Config::Any;

extends 'Catalyst';

# Perl 5.10+ syntax is used
require 5.010_000;

# LizztCMS version
my $VERSION_NO = '0.2';
our $GITREV = '';
our $GITBRANCH = '';
our $VERSION = $VERSION_NO;
our $PATH = $FindBin::RealBin.'/..';

my $SNAPSHOT = 0;

if ($GITREV)
{
    if ($SNAPSHOT)
    {
        $VERSION = $VERSION_NO.' git snapshot ('.$GITREV.'/'.$GITBRANCH.')';
    }
    else
    {
        $VERSION = $VERSION_NO.' release ('.$GITREV.')';
    }
}
else
{
    $VERSION = $VERSION_NO.' git';
    if (-d './.git')
    {
        open(my $i,'-|','git','rev-parse','--abbrev-ref','HEAD');
        $VERSION .= '/'.<$i>;
        close($i);
    }
}

# Configure the application. 
#
# Note that settings in lizztcms.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( 
    name => 'LizztCMS',
    encoding => 'UTF-8'
);

my $confFile = '.';
if(not -e $PATH.'/lib/LizztCMS.pm')
{
    # This is a somewhat hacky solution to avoid having to load File::Basename here
    ($PATH = __FILE__) =~ s{/lib/LizztCMS\.pm$}{};
    $confFile = $PATH;
}
$confFile .= '/lizztcms.yml';
__PACKAGE__->config( 'Plugin::ConfigLoader' => { file => $confFile } );

__PACKAGE__->config->{session} = 
{
    expires => 7200,
};
__PACKAGE__->config->{authentication} =
{   
    # We've currently only got one realm, users
    default_realm => 'users',
     realms => {
         users => {
             credential => {
                 class => 'Password',
                 password_field => 'password',
                 password_type => 'hashed',
                 password_hash_type => 'MD5',
             },
             store => {
                 class => 'DBIx::Class',
                 user_class => 'LizztCMSDB::LzUser',
                 id_field => 'user_id',
                 role_relation => 'roles',
                 role_field => 'role_name',
            }
         }
     }
 };
__PACKAGE__->config->{'Plugin::Cache'}{backend} = {
     class   => "Cache::Memcached::Fast",
     utf8 => 1,
};
__PACKAGE__->config('View::JSON' => {
        expose_stash => 'json_response'
    });

my @additionalPlugins;

{
    # Load the config file to check the logToFile parameter
    my $conf = Config::Any->load_files( { files =>  [ $confFile ], use_ext =>1, flatten_to_hash => 1 } );
    my $logToFile = $conf->{$confFile}->{'LizztCMS'}->{logToFile};
    # If we have a true logToFile parameter, switch to using Log::Handler instead
    # of our builtin log implementation. If we don't have one, use the normal
    # log handler.
    if ($logToFile && $logToFile ne 'false')
    {
        push(@additionalPlugins,'Log::Handler');
        __PACKAGE__->config->{'Log::Handler'} = {
                filename => $logToFile,
                fileopen => 1,
                mode => 'append',
                newline => 1,
        };
    }
    else
    {
        __PACKAGE__->log( LizztCMS::HelperModules::Log->new );
    }
}


# Start LizztCMS
__PACKAGE__->setup(@additionalPlugins);

1;
