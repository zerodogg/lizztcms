package LIXUZ::HelperModules::Mailer;
use Moose;
use JSON qw(encode_json);
use Carp;
use IPC::Open2;

has '_mails' => (
    is => 'ro',
    default => sub { [] },
);

has '_defaultFrom' => (
    is => 'ro',
    builder => '_buildFrom',
);

has 'c' => (
    is => 'rw',
    required => 1,
);

sub add_mail
{
    my $self = shift;
    my $settings = shift;

    my $recipients  = $settings->{recipients};
    my $subject     = $settings->{subject};
    my $contentText = $settings->{message_text};
    my $contentHtml = $settings->{message_html};
    my $from        = $settings->{from};

    if (!ref($recipients))
    {
        $recipients = [ $recipients ];
    }

    if (scalar @{$recipients} < 1)
    {
        carp('add_mail(): no recipients');
    }
    if (!defined($contentHtml) && !defined($contentText))
    {
        carp('add_mail(): no content');
    }
    if (!defined($subject))
    {
        carp('add_mail(): no subject');
    }
    if(
        defined $self->c->config->{LIXUZ}->{email_to_override} && 
        (not $self->c->config->{LIXUZ}->{email_to_override} eq 'false') &&
        length $self->c->config->{LIXUZ}->{email_to_override})
    {
        if ($contentHtml)
        {
            $contentHtml = 'ORIGINAL TO: '.join(',',@{ $settings->{recipients} })."\n\n".$contentHtml;
        }
        if ($contentText)
        {
            $contentText = 'ORIGINAL TO: '.join(',',@{ $settings->{recipients} })."\n\n".$contentText;
        }
        $recipients = [ $self->c->config->{LIXUZ}->{email_to_override} ];
    }
    push(@{ $self->_mails }, {
            distinct_to => $recipients,
            from => $from,
            subject => $subject,
            message_text => $contentText,
            message_html => $contentHtml,
    });
}

sub send
{
    my $self = shift;
    my $from = $self->_defaultFrom;

    my $result = {
        api => 1,
        version => $self->c->stash->{VERSION},
        default_from => $from,

        noFork => 0,
        debug => 0,

        emails => $self->_mails,
    };
    open2(my $out, my $in, $LIXUZ::PATH.'/tools/lixuz-sendmail.pl') or die("Failed to open2 to lixuz-sendmail-pl\n");
    my $pid = print {$in} encode_json($result);
    close($in);
    waitpid($pid,0);
    close($out) if $out;
}

sub _buildFrom
{
    my $self = shift;
    my $from_address = $self->c->config->{LIXUZ}->{from_email};
    if(not $from_address)
    {
        $self->c->log->error('from_email is not set in the config, using dummy e-mail');
        $from_address = 'EMAIL_NOT_SET_IN_CONFIG@localhost';
    }
    return $from_address;
}

__PACKAGE__->meta->make_immutable;