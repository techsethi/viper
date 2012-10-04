checkwebsite, by checkwebsite.org
Please check back at checkwebsite.org for updates.

Download Perl interpreter from:
  http://www.activestate.com - Windows
  http://www.perl.com        - Linux

How to execute the script:

  How "Responser2.pl" works.

  Files inlcuded:
   1. responser.pl      - the executable script
   2. urls.txt          - List of url's to check, read by the script.
                          One address per line.http:// is required
   3. SMTP_Settings.txt - SMTP settings
   4. README.txt        - This file

At the beginning of the script there is a section "Program Seetings", which is the only place 
that you have to change settings.(if you are not familiar in Perl off course).
The section looks like this:

#################################################################
#             Program  Settings
#
my $error_log  = 'Responser_errors.txt';  # File to store errors of program
my $input_file = 'urls2.txt';             # From where program will read WEB Addresses
my $smtp_file  = 'SMTP_Settings.txt';     # File for SMTP Settings
my $send_mail  = 1;                       # my $send_mail  = 1; ->SMTP option is ON,
                                          # my $send_mail  = 0; ->SMTP option is OFF
##################################################################

First line: This is the file which should be used to store the errors. Is not
neccessary, can be deleted at any time.

The second line: The file which are stored the URLs that you want to be verified.
                 Its called "urls2.txt",
		See header on file for details about field formats 
+-------------------------------------------------------+
|!!! IMPORTANT!!! DO NOT USE THIS FOR WINDOWS PATH:     |
|             C:\Programs\scripts\myscript.pl - WRONG   |
| USE THIS:   C:/Programs/scripts/myscript.pl - OK      |
+-------------------------------------------------------+

The third line: The file from which SMTP settings are readed. Its called "SMTP_Settings.txt",
#################################
#                               #
#   Settings for SMTP server    #
#                               # 
#################################

#################
# SMTP Server Host
# Put your SMTP host
SMTPHost = 'cmailer.indiatimes.com'

#################
# MAIL Recipient
Recipient = 'pradeep.sethi@indiatimes.co.in'

#################
# Reverse mail (From who has been sended this e-mail)
# !! IMPORTANT!!  Domain of the return mail MUST EXIST
Reverse = 'pradeep.sethi@indiatimes.co.in'

#################
# END # Do not remove that diggit.
1;

The Fourth line:
	my $send_mail  = 1;   #my $send_mail  = 1; ->SMTP option is ON
			      #my $send_mail  = 0; ->SMTP option is OFF

If you don't want the script to send mail if the status is DOWN or WRONG change my $send_mail to 0


The script works like this: Makes a connections to the server for every URL in the list. It waits until it receive the whole
content of the page and then it report time that was needed for this connection. If some URL in the list is not valid with
valid format, then this URL is saved in the log with status WRONG and the script send email. If the URL is not responsing
then its saved with status DOWN and the script send mail with the error that was returned. If everything is fine, 
status ACCEPTED is saved for the URL in the log with the time that was needed to receive the whole content, 
no email will be sent.

The result of the verification is saved to text file with date as name, example:
report-31.Mar.2005.txt
report-28.Jun.2004.txt
If the file exists, it will be append, otherwise will be created a new file.

#####################################
#
#	How to use:
#	On windows, use the task scheduler;
#	On Linux, you can put a line on a crontab like this:
#
# 	*/10 * * * * (cd /opt/website_monitor ; ./responser2.pl; ) >/dev/null 2>&1
#
#	This will check your servers every 10 minutes.
#
#####################################
