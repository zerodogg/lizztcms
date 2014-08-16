#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use File::stat;
use Term::ReadLine;
use Data::Dumper;
$| = 1;
print "Initializing...";
use lib $FindBin::RealBin.'/../lib/';
# LizztCMS doesn't like not being in its own dir when initializing
chdir($FindBin::RealBin.'/..');
require LizztCMS;
use LizztCMS::HelperModules::Scripts qw(fakeC);

sub restart
{
    print "Restarting...\n";
    exec($0,@ARGV);
}

sub mainLoop
{
    my $c = fakeC();
    print "done\n\n";

    my $doFile = shift;
    if ($doFile && -e $doFile)
    {
        print "Press enter to source $doFile, otherwise press ctrl+c\n";
        <STDIN>;
        no strict;
        do($doFile);
        use strict;
    }
    print "Welcome to lizztcms_console. This is a very basic REPL\n";
    print "with limited access to LizztCMS internals (ie. parts of \$c will work).\n\n";
    my $rl = Term::ReadLine->new('LizztCMS');
    # REPL bits based upon http://blog.zerodogg.org/2010/03/02/a-very-simple-one-liner-repl-for-perl/
    while(defined($_ = $rl->readline("LizztCMS> ")))
    {
        no strict;
        $ret=Dumper(eval($_));
        $err=$@;
        if($err ne "")
        {
            print $err;
        }
        else
        {
            print $ret;
        }
    }
}

mainLoop(@ARGV);
