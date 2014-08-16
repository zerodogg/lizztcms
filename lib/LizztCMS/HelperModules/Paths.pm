package LizztCMS::HelperModules::Paths;
use strict;
use warnings;
use Method::Signatures;
use Exporter qw(import);
use File::Basename qw(dirname);
our @EXPORT = qw(lizztcmsFSPathTo lizztcmsFSRoot);

func lizztcmsFSPathTo($file)
{
    my $path = lizztcmsFSRoot();
    $path .= '/'.$file;
    return $path;
}

func lizztcmsFSRoot ()
{
    my $path;
    no warnings;
    $path = $LizztCMS::PATH;
    use warnings;
    if (!defined $path || !length($path))
    {
        # Use alternate detection
        my $selfPath = $INC{'LizztCMS/HelperModules/Paths.pm'};
        if (!defined $selfPath)
        {
            die('Error: Failed to locate LizztCMS root (primary and fallback both failed)'."\n");
        }
        while(!-e $selfPath.'/lib/LizztCMS.pm' || !-e $selfPath.'/lizztcms.yml')
        {
            $selfPath = dirname($selfPath);
            if ($selfPath eq '/')
            {
                die('Error: Fallback detection of LizztCMS root failed'."\n");
            }
        }
        return $selfPath;
    }
    return $path;
}

1;
__END__

=pod

=head1 DESCRIPTION

This module provides an interface to retrieve the path to where LizztCMS is installed
or to a file contained in some subdirectory of LizztCMS. For the most part it is just
a small wrapper around $LizztCMS::PATH which is a bit more explicit and avoids
warnings.

=head1 SYNOPSIS

    use LizztCMS::HelperModules::Paths;
    my $lizztctl = lizztcmsFSPathTo('/tools/lizztctl')

=head1 FUNCTIONS

The following functions are available from this module and are exported by default.

=over

=item lizztcmsFSPathTo(path);

This returns the fully qualified path to a file contained beneath the LizztCMS
root tree. This does not check if the provided file actually exists, so that
should be done by the caller. Paths provided must start with /.

=item lizztcmsFSRoot()

This provides the fully qualified path to the LizztCMS root tree.

=back
