package LizztCMS::HelperModules::Version;
use strict;
use warnings;
use Method::Signatures;
use Exporter qw(import);
use LizztCMS::HelperModules::Paths qw(lizztcmsFSPathTo);
our @EXPORT = qw(lizztcmsVersion);

my $version;

func lizztcmsVersion ($c = undef)
{
    no warnings;
    if(defined $LizztCMS::VERSION && $LizztCMS::VERSION ne '-1')
    {
        return $LizztCMS::VERSION;
    }
    use warnings;

    if(defined $version)
    {
        return $version;
    }

    if(defined $c && $c->can('stash') && $c->stash && $c->stash->{VERSION})
    {
        $version = $c->stash->{VERSION};
        return $version;
    }

    # HERE THERE BE DRAGONS!
    # This is about as ugly as it gets, but it will "mostly" work when you really
    # need a version number without loading LizztCMS.
    my $path = lizztcmsFSPathTo('lib/LizztCMS.pm');
    if (!-e $path)
    {
        return '(unknown)';
    }
    open(my $i,'<',$path);
    my($base,$gitrev);
    while(<$i>)
    {
        chomp;
        if (/^my \$VERSION_NO/)
        {
            $base = $_;
            $base =~ s/^\D+//;
            $base =~ s/\D+$//;
        }
        elsif(/^our \$GITREV/)
        {
            $gitrev = $_;
            $gitrev =~ s/^our\s+\S+\s*=\s*\S//;
            $gitrev =~ s/\S;.*//;
        }
    }
    close($i);
    if(defined $base && length($base))
    {
        $version = $base;
        if(defined $gitrev && length($gitrev))
        {
            $version .= ' ('.$gitrev.')';
        }
    }
    else
    {
        $version = '(unknown)';
    }
    return $version;
}

1;
