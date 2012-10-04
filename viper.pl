#!/usr/bin/perl -w
# PLEASE READ THE ENTIRE README.txt FILE FIRST!
use warnings;
use strict;
use Tie::File;
use Net::SMTP;
use LWP::UserAgent;
use Data::Dumper;

#################################################################
#             Program  Settings
#
my $error_log = 'viper_errors.txt';    # File to store errors of program
my $input_file = 'urls.txt';    # From where program will read WEB Addresses
my $smtp_file = 'smtp_settings.txt';  # File for SMTP Settings
my $send_mail = 1;                    # my $send_mail  = 1; ->SMTP option is ON,
                                      # my $send_mail  = 0; ->SMTP option is OFF
my $VERBOSE   = 1;

##################################################################
#                      END OF SETTINGS
# Do not edit bellow if you dont understand it.
##################################################################
die "File $input_file is not exist\n"                unless ( -e $input_file );
die "SMTP is ON, but file $smtp_file is not exist\n" unless ( -e $smtp_file );
my @hostInfo;
my $localtime = localtime;
our @errors;
my ( $day, $month, $date, $hour, $year ) = split /\s+/, scalar localtime;
my $output_file = 'report-' . $date . '.' . $month . '.' . $year . '.txt';
print "Script Begin...\nWould log to $output_file\n" if $VERBOSE;

my ( $smtp_host, $recipient, $reverse_path, @all_addr ) = ();
tie @all_addr, 'Tie::File', $input_file
  or error("Cant open $input_file to read addresses");
if ( -e $output_file ) {
    open( OUT, ">> $output_file" )
      or error("Cant open exist file $output_file for append");
}
else {
    open( OUT, "> $output_file" )
      or error("Cant open new file $output_file for writting");
}
my @smtp_settings;
if ( $^O =~ /win/i ) {
    tie @smtp_settings, 'Tie::File', $smtp_file,, recsep => "\012"
      or error("Cant open $smtp_file to read SMTP settings");
}
else {
    tie @smtp_settings, 'Tie::File', $smtp_file, autochomp => '0'
      or error("Cant open $smtp_file to read SMTP settings");
}
for (@smtp_settings) {
    chomp;
    next if /^#/;
    next if /^$/;
    if (/^(\w+)\s=\s'(\S+)'/) {
        $smtp_host    = $2 if ( $1 eq 'SMTPHost' );
        $recipient    = $2 if ( $1 eq 'Recipient' );
        $reverse_path = $2 if ( $1 eq 'Reverse' );
    }
}
print OUT "\n+" . ( '-' x 84 ) . "+\n";
print OUT "|", ' ' x 30, "Time: $hour", ' ' x 40, "|\n";
print OUT "|", ' ' x 10, 'HOST', ' ' x 37, 'STATUS', ' ' x 7,
  "RESPONSE            |\n";
print OUT "+" . ( '-' x 84 ) . "+\n";
for ( 0 .. $#all_addr ) {

    chop $all_addr[$_] if ( $all_addr[$_] =~ /\s+$/ );
    next               if ( $all_addr[$_] =~ /^#/ );     # ignore comments and
    next               if ( $all_addr[$_] =~ /^$/ );     # empty lines

    @hostInfo = split( /\t/, $all_addr[$_] );
    if ( $hostInfo[0] =~ /^http:\/\/\S+\.\w{2,4}$/ )
    {    #address will beginnig with "http://", next some string
                                 # finish with point and 2 to 4 letters
        check_url(@hostInfo);    #call subroutine check_url()
    }
    elsif ( $hostInfo[0] =~ /^smtp:\S+\.\w{2,4}$/ )
    {    #address will beginnig with "smtp:" ,next some string
                                  # finish with point and 2 to 4 letters
        check_smtp(@hostInfo);    #call subroutine check_smtp()
    }
    else {
        my $out_format = sprintf "| %-50.50s %-10s  %-20s|\n", $hostInfo[0],
          "WRONG", "N/A";
        printf OUT $out_format;
        printf $out_format;
        push @errors, "$hostInfo[0] is WRONG Address.";
    }
}
print "All checks done...\n";
my $err = join "\015\012", @errors;
my $err_num = scalar @errors;    # How match DOWN + WRONG Sites have
$send_mail = 0 unless $err_num;

if ($send_mail) {
    print "Initializing mail [$smtp_host]..." if ($VERBOSE);
    my $smtp = Net::SMTP->new(
        $smtp_host,
        Debug   => 1,
        Timeout => 20,
    ) or error("Cant connect to $smtp_host");
    print "Ok\n" if $VERBOSE;
    print Dumper $smtp;

    # Begin Compare mail message
    my $msg = <<__END_OF_MAIL__;
To: $recipient
Subject: $err_num Error Sites | $localtime .
$localtime
$err

__END_OF_MAIL__

    # End Compare

    $smtp->mail("$reverse_path")
      or error("Failed to specify a reverse-path");    #  If all is OK
    $smtp->to($recipient)
      or error("Failed to specify a recipient");       #  that will
    $smtp->data( [$msg] ) or error("Failed to send a message");    #  send mail
    $smtp->quit or error("Failed to quit");                        #  to You
}
else {
    print "Send Mail is OFF\n" if $err_num; # If you do not wish to receive mail
}

close OUT or error("Unable to close file $output_file");
print "\nProcess FINISH\n";

sub check_url {                             # subroutine who check given URL
    ( my $target, my $response_slow, my $response_timeout, my $response_code ) = @_;

    print "Checking $target ...\n";
    my $ua = LWP::UserAgent->new;
    $ua->agent( "$0/0.1 " . $ua->agent );
    $ua->timeout($response_timeout);        # connection timeout
    my $req = HTTP::Request->new( GET => "$target" );
    $req->header( 'Accept' => 'text/html' );    #Accept HTML Page
                                                # send request
    my $start = time;                           # Start timer
    my $res   = $ua->request($req);

	# print Dumper $res;
	
    # check the outcome
    if ( $res->is_success ) { # Success....all content of page has been received
        my $time = time;      # End timer
        $time = ( $time - $start );    # Result of timer
        running_message( "web", $target, $time, $response_slow );
    }
    elsif ($res->{'_rc'} == $response_code)
	{
	    running_match_message($target, $response_code);
	}
	else
	 {
        # Error .... Site is DOWN and script send e-mail to you..
        down_message( "web", $target, $res->{'_rc'} );
    }
}

sub check_smtp {                       #subroutine to check smtp servers
    ( my $hostInfo, my $response_slow, my $response_timeout ) = @_;

    my @hostName = split( /:/, $hostInfo );
    my $target = $hostName[1];

    my $start = time;
    my $smtp  = Net::SMTP->new(
        $target,
        -Debug   => 1,
        -Timeout => $response_timeout,
        -Hello   => "$target"
    );
    if ( $! == 0 ) {
        my $time = time;
        $time = ( $time - $start );    # Result of timer
        running_message( "mail", $target, $time, $response_slow );
        $smtp->quit();
    }
    else {
        down_message( "mail", $target );
    }

}

sub running_message {
    ( my $type, my $target, my $time, my $response_slow ) = @_;
    my $out_format;

    if ( $response_slow && ( $response_slow <= $time ) ) {
        push( @errors, "Slow response from ($type) $target\: $time seconds" );
        $out_format = sprintf "| %-4s %-50.50s %-10s %-20s |\n", $type,
          $target, "SLOW", "Response $time seconds";
    }
    else {
        $out_format = sprintf "| %-4s %-50.50s %-10s %-20s |\n", $type,
          $target, "ACCESSED", "Response $time seconds";
    }
    print OUT $out_format;    # write to file
    print $out_format;        # print to console
}

sub running_match_message {
    ( my $target, my $response_code ) = @_;
    my $out_format;

        $out_format = sprintf "| %-4s %-50.50s %-10s %-20s |\n", "web",
          $target, "RESPONSE CODE MATCHED", "Response : $response_code";
    print OUT $out_format;    # write to file
    print $out_format;        # print to console
}

sub down_message {
    ( my $type, my $target, my $rc ) = @_;

    my $out_format = sprintf "| %-4s %-50.50s %-10s %-20s |\n", $type, $target,
      "DOWN [$rc] ", " N/A";
    push( @errors, "($type) $target is DOWN [$rc]." )
      or error("Cannot push error for DOWN");
    print OUT $out_format;    # write to file
    print $out_format;        # print to console
}

sub error {                   # subroutine who print in Error Log
    my $error_msg = shift;
    open ERR, ">> $error_log" or die "Cannot open log file $error_log : $!\n";
    print ERR "$localtime\: $error_msg : $!\n";
    close ERR or die "Cannot close log file $error_log : $!\n";
}
