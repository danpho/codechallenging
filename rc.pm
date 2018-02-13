package rc;
use strict;
use warnings;
use Term::ANSIColor; #Set the text color for output.
use sys_perl;


# The example module could be path/to/the/modules/NameOfTheProject/SomeModule.pm


sub read_custmz   #$rc_1:string for user info;$rc_2 default value 
{
  my($rc_info,$rc_value)=(@_);
  chomp($rc_info);chomp($rc_value);
  print "Please input ",colored("$rc_info","bold green")," (ENTER for ",colored("$rc_value","bold cyan"),"): ";
  $_=<STDIN>;
  chomp($_);
  if (length($_) == 0)
  {$_=$rc_value;}
  return $_; 
}#end of sub read_custmz

1;

####
####
####
#####!/usr/bin/perl -w
#####set the strict condition;
####use strict;
####use warnings;#give a warning message when error occured
####use diagnostics; #When you do not understand the warning message, use it to learn more info.It cost a lot of resource!
####use Scalar::Util qw(looks_like_number);   #used to test numeric value. OR if ($var =~ /^[+-]?/d+/$/ ){...}
####use Term::ANSIColor; #Set the text color for output. color: red, cyan, green, yellow, blue,CLEAR, RESET, BOLD, DARK, UNDERLINE, UNDERSCORE, BLINK, REVERSE, CONCEALED, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, ON_BLACK, ON_RED, ON_GREEN, ON_YELLOW, ON_BLUE, ON_MAGENTA, ON_CYAN, and ON_WHITE 
#####    print color 'bold blue';
#####    print "This text is bold blue.\n";
#####    print color 'reset';
#####    print "This text is normal.\n";
#####    print colored ("Yellow on magenta.", 'yellow on_magenta'), "\n";
#####    print "This text is normal.\n";
#####    print colored ['yellow on_magenta'], 'Yellow on magenta.';
#####    scalar(grep $_, @a)
#####    print "\n"; \n";
####
####
####my $SCRIPT_NAME="read_customerized.pl";   #program name
####
####my $line;     # to store line read from a file
####my @values;   # to parse each word in the $line read from a file
####
###### write commands to command file for record
####my $datelog=`date`;
####$datelog=trim($datelog);
####system("echo '$datelog  $SCRIPT_NAME' >> command");   #if running this script, write it into command for record
####
####
####
####
####
####sub trim 
####{
####my ($sub_line)=@_;
####chomp($sub_line);
####$sub_line=~s/^\s+|\s+$//g;
####return $sub_line;
####}
