#!/usr/bin/perl
use strict;
use warnings;

my $hasDone = 0;
my $logfile = $ENV{HOME}.'/lizztcms_upgrade.log';

if(not @ARGV)
{
    idie("Usage: [script] /path/to/directory\n");
}

if(not defined $ENV{HOME} or not length $ENV{HOME})
{
    idie("The environment variable HOME is missing\n");
}

my $extraLibsMessage = "If you need to supply additional perl library paths to this script\nset the environment variable PERL5LIB to a : separated\nlist of additional paths.";
if ($ENV{SUDO_COMMAND})
{
    $extraLibsMessage .= " It is worth noting that \"sudo\" does not\ninherit environment variables by default, and as this installer is running\nunder sudo, your PERL5LIB variable may have been lost during the sudo.\n Try running 'sudo PERL5LIB=\"\$PERL5LIB\" COMMAND' instead.";
}
if ( system('perl','DEPSLIST','check') != 0)
{
	print "\n$extraLibsMessage\n";
	print "\nAborting due to unsatisfied dependencies.\n";
	print "Install the missing modules, then re-run the installer/upgrader.\n";
	exit(1);
}

foreach my $path(@ARGV)
{
    if (-e $path)
    {
        upgradeInstall($path);
    }
    else
    {
        installLizztCMS($path);
    }
    $hasDone = 1;
}

exit(0);

sub upgradeInstall
{
    my $path = shift;
    print "$path: exists, assuming upgrade\n";
    if (not -d $path)
    {
        idie("$path: exists but is not a directory\n");
    }
    if(not -e $path.'/lizztcms.yml' or not -e $path.'/lib/LizztCMS.pm')
    {
        idie("$path: does not look like a LizztCMS install\n");
    }
    if (not -w $path)
    {
        idie("$path: is not writable to me\n");
    }
    my $r = system('./script/lizztcms_upgrade.pl','--chained','--logfile',$logfile,$path);
    if ($r != 0)
    {
        idie("Upgrade script returned nonzero.\n");
    }
}

sub installLizztCMS
{
    my $path = shift;
    print "$path: does not exist, assuming fresh install\n";
    my $r = system('./script/lizztcms_install.pl',$path);
    if ($r != 0)
    {
        idie("Installation script returned nonzero.\n");
    }
}

sub idie
{
    my $message = shift;
    $message = 'Error: '.$message;
    if(not $hasDone)
    {
        die($message);
    }
    else
    {
        print $message;
        print "Press enter to exit this script (and clean up temporary files)\n";
        <STDIN>;
        exit(1);
    }
}
