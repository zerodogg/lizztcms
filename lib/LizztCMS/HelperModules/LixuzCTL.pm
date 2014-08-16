package LizztCMS::HelperModules::LizztCMSCTL;
use strict;
use warnings;
use Method::Signatures;
use LizztCMS::HelperModules::Paths qw(lizztcmsFSPathTo lizztcmsFSRoot);
use Exporter qw(import);
our @EXPORT = qw(lizztctl lizztctlCommand);

func lizztctl(@ARGS)
{
    my $success = 0;
    my $r = system(lizztctlCommand(@ARGS));
    if ($r == 0)
    {
        $success = 0;
    }
    if(wantarray())
    {
        return($success,$r);
    }
    return $success;
}

func lizztctlCommand (@ARGS)
{
    my $lizztcmsCTLPath = lizztcmsFSPathTo('/tools/lizztctl');
    if (!-e $lizztcmsCTLPath)
    {
        die($lizztcmsCTLPath.': does not exist'."\n");
    }
    elsif (!-x $lizztcmsCTLPath)
    {
        die($lizztcmsCTLPath.': is not executable'."\n");
    }
    my @command = (lizztcmsFSPathTo('/tools/lizztctl'), qw(--quiet --web-chained), '--lizztcmsdir',lizztcmsFSRoot());
    push(@command,@ARGS);
    return @command;
}

1;
__END__

=pod

=head1 DESCRIPTION

This module provides access to run lizztctl() commands from inside the LizztCMS web
application.

Note: if the /tools/lizztctl file is missing or has wrong permissions when
either of the functions within this module is called the function will die with
an error message.

=head1 SYNOPSIS

    use LizztCMS::HelperModules::LizztCMSCTL;
    lizztctl(..)

=head1 FUNCTIONS

The following functions are available from this module and are exported by default.

=over

=item lizztctl(arg1,arg2,..)

This provides access to running lizztctl commands within LizztCMS. It takes any
parameters that lizztctl normally takes. It will then execute lizztctl with
said parameters and return the status from lizztctl. In scalar context it
returns a boolean value, where true means lizztctl completed successfully and
false means lizztctl failed. In list context it will reeturn
($success,$returnValue) where $success is the previously mentioned boolean, and
$returnValue is the raw return value as returned from the system() call.

=item lizztctlCommand(arg1,arg2,..)

This is similar to lizztctl(), but instead of executing lizztctl it will instead
return an array containing the parameters that would have been provided to system()
by lizztctl() in order to run lizztctl with the provided parameters.

=back
