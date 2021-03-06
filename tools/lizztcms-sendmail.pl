#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use JSON qw(decode_json);
use MIME::Lite;
use Getopt::Long;
use Try::Tiny;
use Time::HiRes qw(time sleep);
use POSIX qw(setsid);
use Encode qw(encode);
use IO::Socket::UNIX;
use IO::Select;
use Method::Signatures;
use utf8;

my $lizztcmsVersion = 'GIT';
my $logfile = '/dev/shm/lizztcms-sendmail-'.$$.'.log';
my $fork = 1;
my $debug = 0;
my $dupeProtection = 0;
my $lizztcmsSendmailID = time.'-'.int(rand(9999));
my $socket;
my @queue;
my %state;

# Read and parse the JSON
{
    my $JSON = '';
    my $J;
    setState('Reading data');
    while(<STDIN>)
    {
        $JSON .= $_;
    }
    try
    {
        $J = decode_json($JSON);
        if(not ref($J))
        {
            die("Result is not a reference\n");
        }
        elsif(ref($J) ne 'HASH')
        {
            die("Result is not a hash reference: ".ref($J)."\n");
        }
    }
    catch
    {
        die("Failed to decode JSON from STDIN: $_");
    };

    # Populate the queue
    setState('Populating queue');
    try
    {
        $J->{api} //= '(unknown)';
        if ($J->{api} ne '1')
        {
            die("Unsupported API version: ".$J->{api}."\n");
        }
        foreach my $distinct (@{ $J->{emails} })
        {
            foreach my $recipient (@{ $distinct->{distinct_to} })
            {
                populateWith( $recipient,$distinct->{subject}, $distinct->{message_html}, $distinct->{message_text}, $distinct->{from}, $J->{default_from} );
            }
        }
        if ($J->{version})
        {
            $lizztcmsVersion = $J->{version};
        }
        if ($J->{noFork})
        {
            $fork = 0;
        }
        if ($J->{debug})
        {
            $debug = 1;
        }
        if ($J->{dupeProtection})
        {
            $dupeProtection = 1;
        }
        if ($J->{socket})
        {
            if (-e $J->{socket})
            {
                die($J->{socket}.': already exists - refusing to listen'."\n");
            }
            $socket = IO::Socket::UNIX->new(
                Type => SOCK_STREAM,
                Local => $J->{socket},
                Listen => 1,
            ) or die("Failed to listen to ".$J->{socket}.': '.$!."\n");
        }
    }
    catch
    {
        die("lizztcms_sendmail.pl: Failed to populate e-mail queue: $_");
    };
}
# Daemonize
if ($fork)
{
    open(STDOUT,'>',$logfile);
    open(STDERR,'>',$logfile);
    my $newPID = fork;
    exit(0) if $newPID;
    die("Failed to fork: $!\n") if not defined($newPID);

    setsid();
}

if ($socket)
{
    setState('Listening on socket: '.$socket->hostpath);
    my $selector = IO::Select->new( $socket );
    my $finished = 0;
    while(my (@available) = $selector->can_read(10))
    {
        setState('Processing socket input');
        foreach my $client (@available)
        {
            if ($client eq $socket)
            {
                $selector->add($client->accept);
            }
            else
            {
                my $buffer = <$client>;
                if(defined $buffer)
                {
                    my $content = decode_json($buffer);
                    if ($content->{END})
                    {
                        printd('Received END request, closing sockets');
                        my $path = $socket->hostpath;
                        close($client);
                        close($socket);
                        unlink($path);
                        $finished = 1;
                        last;
                    }
                    elsif(!defined $content)
                    {
                        warn('WARNING: Failed to decode JSON'."\n");
                        next;
                    }
                    foreach my $recipient (@{ $content->{distinct_to} })
                    {
                        printd('Added recipient: '.$recipient);
                        populateWith( $recipient,$content->{subject}, $content->{message_html}, $content->{message_text}, $content->{from}, 'FIXME');
                    }
                }
                else
                {
                    $selector->remove($client);
                    close($client);
                }
            }
        }
        if ($finished)
        {
            last;
        }
        setState('Listening on socket: '.$socket->hostpath);
    }
    if (!$finished)
    {
        printd('Finished without receiving END. Going ahead with processing of received content.');
    }
    setState('Finished processing socket data');
    if (!@queue)
    {
        printd('No queue data after socket processing');
    }
}

# Start processing
{
    while(my $m = shift(@queue))
    {
        setState('Processing queue');
        trySend($m);
        sleep(0.1);
    }
}

# Remove the logfile if it's empty
if (-s $logfile == 0)
{
    unlink($logfile);
}

func trySend($mail)
{
    if (!defined($state{ $mail->{ID} }))
    {
        printd('Attempted to process an e-mail that has been removed from state: '.$mail->{ID}.' - ignoring request');
        return 1;
    }

    my $content = $mail->{type} eq 'HTML' ? $mail->{HTML} : $mail->{text};

    my $subject = $mail->{subject};

    my $type = $mail->{type} eq 'HTML' ? 'text/html' : 'text/plain';
    $type .= '; charset=UTF-8';

    if ($mail->{to} !~ /@/)
    {
        warn('Skipping illegal to= address: '.$mail->{to}."\n");
        return;
    }

    my $email = MIME::Lite->new(
        From => $mail->{from},
        To => $mail->{to},
        Subject => encode('MIME-B',$subject),
        Type => $type,
        Data => encode('utf8',$$content),
    );
    $email->add('X-LizztCMS-Mailer' => 'lizztcms-sendmail.pl');
    $email->add('X-LizztCMS-Mailer-State' => $lizztcmsSendmailID.'-'.$mail->{ID}.'-'.$state{ $mail->{ID} } );
    $email->replace('X-Mailer' => 'LizztCMS version '.$lizztcmsVersion);
    $state{ $mail->{ID} }++;
    printd('Sending mail with subject "'.$subject.'" to '.$mail->{to});
    my $r = $email->send();
    if ($email->last_send_successful)
    {
        printd('Sending successful');
        delete($state{ $mail->{ID} });
        return 1;
    }
    else
    {
        printd('Sending unsuccessful');

        # Give the mail server 0.5 seconds to recover (plus any waiting time
        # our parent will do anyway)
        sleep(0.5);

        # If we have tried 10 times, sleep longer
        if ( $state{ $mail->{ID} } == 10)
        {
            setState('Sleeping for 5 seconds');
            sleep(5);
        }
        # If we have tried >20 times, give up
        elsif($state{ $mail->{ID} } > 20)
        {
            warn("Giving up on mail with given ID ".$mail->{ID}.": keeps failing\n");
            return 0;
        }
        # If we have tried >10 times, sleep a bit longer
        elsif($state{ $mail->{ID} } > 10)
        {
            setState('Sleeping one second');
            sleep(1);
        }

        # Push it into the back of the queue
        push(@queue, $mail);

        return 0;
    }
}

func populateWith($to,$subject,$HTML,$text,$from,$defaultFrom)
{
    $from //= $defaultFrom;

    if(not defined $subject)
    {
        die("subject: missing\n");
    }
    if(not defined $from)
    {
        die("from: missing\n");
    }
    if(not defined $HTML and not defined $text)
    {
        die("content missing (no message_html or message_text)\n");
    }
    if(not defined $to)
    {
        die("to: missing\n");
    }
    my $type;
    if(defined $text && defined $HTML)
    {
        $type = 'BOTH';
    }
    elsif(defined $text)
    {
        $type = 'TEXT',
    }
    elsif(defined $HTML)
    {
        $type = 'HTML';
    }

    push(@queue, {
            from => $from,
            to => $to,
            text => \$text,
            HTML => \$HTML,
            type => $type,
            subject => $subject,
            ID => genStateID($to),
        });
}

func genStateID($email)
{
    my $ID;
    while( (!defined $ID) || (defined $state{$ID}))
    {
        if ($dupeProtection)
        {
            $email =~ s/.*<([^>]+)>.*/$1/;
            $ID = $email;
        }
        else
        {
            while(!defined($ID) || defined($state{$ID}))
            {
                $ID = time.'-'.int(rand(9999999999));
            }
        }
    }
    if ($state{$ID} && $dupeProtection)
    {
        printd('Duplicate detected: '.$email);
    }
    else
    {
        $state{$ID} = 0;
    }
    return $ID;
}

sub setState
{
    my $state = shift;
    $0 = 'lizztcms-sendmail.pl: '.$state;
    printd($state);
}

sub printd
{
    if ($debug)
    {
        my ($lsec,$lmin,$lhour,$lmday,$lmon,$lyear,$lwday,$lyday,$lisdst) = localtime(time());
        $lmon++;
        $lhour = "0$lhour" if not $lhour >= 10;
        $lmin = "0$lmin" if not $lmin >= 10;
        $lsec = "0$lsec" if not $lsec >= 10;
        $lmon = "0$lmon" if not $lmon >= 10;
        $lmday = "0$lmday" if not $lmday >= 10;
        $lyear += 1900;
        warn("[$lyear-$lmon-$lmday $lhour:$lmin:$lsec ($$)] ".shift(@_)."\n");
    }
}

__END__

=head1 SUMMARY

This program expects a JSON string on STDIN (syntax below). It will read from
STDIN until it reaches EOF, at which point it will parse the string and if it
is successful, daemonize itself and begin processing e-mails.

=head1 JSON FORMAT

(obviously, comments are not usable in the real string)

    {
        // The default 'From:' value. Required.
        default_from: '...',
        // The LizztCMS version (optional)
        version: '',
        // The API version (required)
        api: 1,
        // Forces lizztcms-sendmail.pl not to fork if true (optional)
        noFork: 0,
        // Enables dupe-protection if true (optional)
        dupeProtection: 0,
        // Enables streaming mode (allows messages to be added later) if set to a
        // path (path to the socket to listen to)
        socket: null,

        emails: [
                {
                    // An array of 'To:' values, lizztcms-sendmail.pl will send one
                    // separate e-mail per distinct_to.
                    distinct_to: [ .. ],
                    // If this is omitted, default_from will be used
                    from: '...',
                    // You need to supply at least one of message_html and
                    // message_text
                    message_html: '...',
                    message_text: '...',
                    // Subject is required
                    subject: '...',
                },
            ],
    }
