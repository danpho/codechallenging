#!/usr/bin/perl -w
#set the strict condition;
use strict;
use warnings;#give a warning message when error occured
use diagnostics; #When you do not understand the warning message, use it to learn more info.It cost a lot of resource!
use Scalar::Util qw(looks_like_number);   #used to test numeric value. OR if ($var =~ /^[+-]?/d+/$/ ){...}
use Term::ANSIColor; #Set the text color for output. color: red, cyan, green, yellow, blue,CLEAR, RESET, BOLD, DARK, UNDERLINE, UNDERSCORE, BLINK, REVERSE, CONCEALED, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, ON_BLACK, ON_RED, ON_GREEN, ON_YELLOW, ON_BLUE, ON_MAGENTA, ON_CYAN, and ON_WHITE 

#customerized module
use sys_perl;
use tm;     #module for clean variables,remove whitespace at the very beginning or end. tm::trim(...)
use rc;     #module for read value which may include default one. rc::read_custmz(<info for user(string)>,<value>)

my $SCRIPT_NAME="w_raw_refine.pl";        #program name
my $DFT_RAW_DATA="itcont.txt";            #default raw input file name
my $DFT_PERCENTILE="percentile.txt";      #default percentile file name
my $DFT_REPORT="report.txt";              #default report file name
my $DFT_REPEAT_DONOR="repeat_donors.txt"; #default report file name
my $DFT_DIR="./";                         #default file location
my $DFT_ZIP="02895";                      #default zip code
my $DFT_YEAR="2018";                      #default year
my $line;     # to store line read from a file
my @values;   # to parse each word in the $line read from a file
my @tmp;      # set temp value
my $flag=1;     # to check necessary info, if incomplete, flat=0 and program will not run.
my $info_string;    #string variable which is used to pass info to rc::read_custmz() function
my $default_value;  #default value which is preset by above $DFT*
my $dir_data;       #current location
my $dir_input;      #input data location
my $dir_output;     #output data location
my $dir_module;     #module location

my $filename_raw;   #raw data file name
my $filename_percent; #percentile file name
my $filename_repeat_donor;  #file for data of repeated donor
my $filename_report;  #file for report
my $filename_invalid="invalid_data.txt"; #file for invalid data
#variables for data
my $i;my $j;my $k;  # index or counter
my $ini_no_col;     # initial value of column amount using for comparison to find anormal data, assume the first data is complete one.
my $no_col;         # amount of column per record/data
my $amt_record;     # total record number/amount
my $last_no_col;
my @d_cmte_id;
my @d_name;
my @d_zip;
my @d_date_transaction;
my @d_amt_transaction;
my @d_other_id;
my @d_flag;
my $d_day;
my $d_month;
my $d_year;

my @d_srt_amt_transaction;    #save sorted $d_amt_transaction
my $percentile_value;


my $flag_initial=1;     #for each repeated donators, the 1st record should be saved separately.1:true,0:false
my $d_rpt_target_year;  #for user to choose the interested year
my $d_rpt_target_cmte_id; #for user to choose the interested cmte_id
my $d_rpt_target_zip;     #for user to choose the interested zip
my @d_rpt_cmte_id;
my @d_rpt_name;
my @d_rpt_zip;
my @d_rpt_date_transaction;
my @d_rpt_amt_transaction;
my @d_rpt_amt_total;          #intergral donate amount
my @d_rpt_count;              #count how many repat donors
my @d_rpt_year;

#set arrays for unique cmte_id, zip, and year
#Goal: speed up group and calculation
my @d_grp_uniq_cmte_id;       
my @d_grp_uniq_zip;
my @d_grp_uniq_year;
my $grp_id; my $grp_zip; my $grp_year;    #save each element from related arrays above three
my $flag_grp_found;
my $amt_repeat_donor_rec;

#customized info
print "program info.......\n";

##confirm data location
$info_string="data location";
$default_value=$DFT_DIR;
$dir_data=rc::read_custmz($info_string,$default_value);
$dir_data=tm::trim($dir_data);
@values=split(/\//,$dir_data);

print"values[0]=$values[0]\n";
#convert relative path to absolute directory
if(($dir_data eq ".") or ($dir_data eq "./"))  #current relative path
{$dir_data=`pwd`;$dir_data=tm::trim($dir_data)."/";}    
elsif($#values >= 0)  #identify relative path from absolute path, and convert relative path to absolute path
{
  $values[0]=tm::trim($values[0]);
  if ($values[0] eq ".")
  {$_=tm::trim(`pwd`);$dir_data=$_."/".tm::trim($dir_data)."/";}
  else
  {$dir_data=tm::trim(`pwd`)."/".$dir_data;}
}

#set input, output, and module directory
$dir_input="$dir_data"."input/";
$dir_output="$dir_data"."output/";
$dir_module="$dir_data"."module/";
if(not -d $dir_input){system("mkdir $dir_input;");}
  else{print "./input/ directory exists.\n";}
if(not -d $dir_output){system("mkdir $dir_output;");}
  else{print "./output/ directory exists.\n";}
if(not -d $dir_module){system("mkdir $dir_module;");}
  else{print "./module/ directory exists.\n",colored("Please make sure copy the module files from the website to this directory.\n","bold yellow");}

#confirm raw data file name
$info_string="file name for raw data";
$default_value="$dir_input"."$DFT_RAW_DATA";
$filename_raw=rc::read_custmz($info_string,$default_value);
$filename_raw=tm::trim($filename_raw);

#confirm input percentile 
$info_string="file name for input percentile";
$default_value="$dir_input"."$DFT_PERCENTILE";
$filename_percent=rc::read_custmz($info_string,$default_value);
$filename_percent=tm::trim($filename_percent);

$percentile_value=tm::trim(`head $filename_percent`);

#confirm repeat_donor.txt file name
$info_string="file name for repeated donors";
$default_value="$dir_output"."$DFT_REPEAT_DONOR";
$filename_repeat_donor=rc::read_custmz($info_string,$default_value);
$filename_repeat_donor=tm::trim($filename_repeat_donor);

### confirm interested year
$info_string="your interested year";
$default_value=$DFT_YEAR;
$d_rpt_target_year=rc::read_custmz($info_string,$default_value);

### confirm interested zip code
$info_string="your interested zip code";
$default_value=$DFT_ZIP;
$d_rpt_target_zip=rc::read_custmz($info_string,$default_value);

#confirm report.txt file name
$info_string="file name for report";
$default_value="$dir_output"."$DFT_REPORT";
$filename_report=rc::read_custmz($info_string,$default_value);
$filename_report=tm::trim($filename_report);


$filename_invalid="$dir_output"."$filename_invalid";

#very files existing
if (not -e $filename_raw)
{print "Error,$filename_raw does NOT exist. please check your files.\n";$flag=0;}
if (not -e $filename_percent)
{print "Error,$filename_percent does NOT exist. please check your files.\n";$flag=0;}

if($flag ==1)
{
  open(RAW,"<$filename_raw");
  open(REPEAT,">$filename_repeat_donor");
  open(INVALID,">$filename_invalid");
  open(CAL,">$filename_report") or die "cannot open file >$dir_output/$filename_report for writing:$!\n";
  print INVALID "REASON\tline #(no blank)\toriginal data\n";
  $i=-1;     #point to current data and counter
  while($line=<RAW>)
  {
    $line=tm::trim($line);       #remove control symbol, like \n, space at the end of line
    if(length($line)>0)
    {
      $i++;
      @values=split(/\|/,$line);
      if($i==0){$no_col=$#values;$ini_no_col=$no_col;$last_no_col=$no_col;}
      else
      {$last_no_col=$no_col;$no_col=$#values;}
      $values[0]=tm::trim($values[0]);
      
      print "$ini_no_col\t$last_no_col\t$no_col\n";
      $d_cmte_id[$i]=tm::trim($values[0]);    #CMTE_ID
      $d_name[$i]=tm::trim($values[7]);       #name
      $d_zip[$i]=tm::trim($values[10]);
      $d_date_transaction[$i]=tm::trim($values[13]);
      $d_amt_transaction[$i]=tm::trim($values[14]);
      $d_other_id[$i]=tm::trim($values[15]);

      #check data valid
      ####  check name
      @tmp=split(/,/,$d_name[$i]);
      $_=length($d_name[$i]);
      if ($_==0 or $#tmp ==0)
      {
        #print "$#@_\t len=$_ \t $line\n";
        print "in name len=$_ \t $line\n";
        if($_==0)
        { print INVALID "NO_NAME\tLN:$i\t$line\n";
          print "NO_NAME\t$i\t$line\n";
        }#end if($_==0) 
        else
        { print INVALID "MAL_NAME\tLN:$i\t$line\n";
          print "MAL_NAME \t$i\t$line\n";
        }#end else of if($_==0)
        $d_flag[$i]=0;    #mark data invalid
      }

      ####  check ZIP_CODE
      #ZIP code may consist of alphabit and other non-digit character.
      #Here,first check the total length, if length>=5,
      #then get three values based on general zip format xxxxx-xxxx.. first 5 characters are main part
      #then check whether existing non-digit characters in the main part
      if($d_zip[$i]=~ /(\S+)/)  #zip is not empty or not whitespace character, may be 0-9,a-z,A-Z,+-*/....
      {
        $tmp[0]=$1;   #take the first part of zip code if the zip consists of all non-whitespa in the string. The beginning and end of whitespace has been removed
        if($tmp[0]=~ /(\d+)/)   #check digit number and save in $1
        {
          if(length($1)<5)    #main part of zip has less than 5 digit numbers
          {
            $d_flag[$i]=0;
            print INVALID "FEWER_DIG\tLN:$i\t$line\n";
            print "FEWER_DIG\tLN:$i\t$line\n";
          }
          else  #main part of zip has at least 5 digit numbers +number/other alphabit==> trunk the rest of part
          {$d_zip[$i]=substr($d_zip[$i],0,5);}
        }
      }#end if($d_zip[$i]=~ /(\S+)/)      
      else#zip is empty
      {
        $d_flag[$i]=0;
        print INVALID "NO_ZIP  \tLN:$i\t$line\n";
        print "FEWER_DIG\tLN:$i\t$line\n";
      }#end else#zip is empty

      #### check transaction date
      if(length($d_date_transaction[$i])==8)  #check the length of the date 
      {
        $d_month=substr($d_date_transaction[$i],0,2);$d_month=tm::trim($d_month);$d_month=int($d_month);
        $d_day=substr($d_date_transaction[$i],2,2);$d_day=tm::trim($d_day);
        $d_year=substr($d_date_transaction[$i],4,4);$d_year=tm::trim($d_year);
        if($d_month < 1 or $d_month >12)   #check month out of range
        #if($d_month ne "01" or $d_month ne "02")   #check month out of range
        {$d_flag[$i]=0;print INVALID "om12INVLD_DAT\tLN:$i\t$line\n";print "om12INVLD_DAT\tLN:$i\t$line\n";}
        else    #month in range
        {
          if(($d_month ==1) or ($d_month==3) or ($d_month ==5) or ($d_month ==7) or ($d_month ==8) or ($d_month==10) or ($d_month ==12))    #month with 31 days
          {
            if($d_day <1 or $d_day >31) #out of range of 1-31 days
            {$d_flag[$i]=0;print INVALID "od31INVLD_DAT\tLN:$i\t$line\n";print "od31INVLD_DAT\tLN:$i\t$line\n";}
          }
          elsif(($d_month eq "04") or ($d_month eq "06") or ($d_month eq "09")or ($d_month eq "11")) #month with 30days
          {
            if($d_day <1 or $d_day>30) #out of range of 1-30days
            {$d_flag[$i]=0;print INVALID "od30INVLD_DAT\tLN:$i\t$line\n";print "od30INVLD_DAT\tLN:$i\t$line\n";}
          }
          elsif($d_month ==2)  #month with 28or 29 days
          { 
            if(leapyear($d_year) eq 1)  #leap year
            { if($d_day<1 or $d_day>29) #out of range of 1-29days
              {$d_flag[$i]=0;print INVALID "od29INVLD_DAT\tLN:$i\t$line\n";print "od29INVLD_DAT\tLN:$i\t$line\n";}
            }
            else  #not leap year
            { if($d_day <1 or $d_day>28) #out of range of 1-28days
              {$d_flag[$i]=0;print INVALID "od28INVLD_DAT\tLN:$i\t$line\n";print "od28INVLD_DAT\tLN:$i\t$line\n";}
            }
          }
          else  #month out of range of 1-12 months
          {$d_flag[$i]=0;print INVALID "omINVLD_DAT\tLN:$i\t$line\n";print  "outmonthINVLD_DAT\tLN:$i\t$line\n";}

        }
      }
      else  #invalid date format
      {$d_flag[$i]=0;print INVALID "INVLD_DAT\tLN:$i\t$line\n";}

      ####  check OTHER_ID
      if(length($d_other_id[$i])==0)  
      {$d_flag[$i]=1;$d_other_id[$i]="empty";}
      else  # there is other id, invalid data
      {$d_flag[$i]=0;
       print INVALID "OTHER_ID\tLN:$i\t$line\n";
      }
      print "$i.\nCMTE_ID: $d_cmte_id[$i]\nNAME: $d_name[$i]\nZIP_CODE: $d_zip[$i]\nTRANSACTION_DT: $d_date_transaction[$i]\nTRANSACTION_AMT: $d_amt_transaction[$i]\nOTHER_ID: $d_other_id[$i]\nFLAG_VALID: $d_flag[$i]\n\n";
    }#end if(length($line)>0)
    else   #blank line, skip
    {next;}   #end else if(length($line)>0)  
  }#end while($line=<RAW>)

  $amt_record=$i;   #total record amount

  # find repeat donators
  $i=0;
  for ($j=0;$j<$#d_cmte_id;$j++)
  {
    $flag_initial=1;
    if ($d_flag[$j]==1) #valid data or data has not been marked as repeat one
    {
      for ($k=($j+1);$k<=$#d_cmte_id;$k++)
      {
        if(($d_name[$j] eq $d_name[$k]) and ($d_zip[$j] eq $d_zip[$k]) and ($d_zip[$j] eq $d_rpt_target_zip))
        {
          if($flag_initial==1)#new search and find the first match one,save the first one
          {
            $d_rpt_amt_total[$i]=$d_amt_transaction[$j] unless defined $d_rpt_amt_total[$i]; #if element not initialized, set initial value
            $d_rpt_count[$i]=1 unless defined $d_rpt_count[$i];
            $d_rpt_cmte_id[$i]=$d_cmte_id[$j];
            $d_rpt_name[$i]=$d_name[$j];
            $d_rpt_zip[$i]=$d_zip[$j];
            $d_rpt_date_transaction[$i]=$d_date_transaction[$j];
            $d_rpt_amt_transaction[$i]=$d_amt_transaction[$j]; 
            $d_rpt_year[$i]=substr($d_rpt_date_transaction[$i],4,4);  #transaction year
            print REPEAT  "$d_rpt_cmte_id[$i]|$d_rpt_name[$i]|$d_rpt_zip[$i]|$d_rpt_date_transaction[$i]|$d_rpt_amt_transaction[$i]\n";
            print "$d_rpt_cmte_id[$i]|$d_rpt_name[$i]|$d_rpt_zip[$i]|$d_rpt_date_transaction[$i]|$d_rpt_amt_transaction[$i]\n";
            $flag_initial=0;    # the first value has been set

            $i++;
          }#end if(($flag_initial==1)#new search and find the first match one, save the first one

          $d_flag[$j]=-1;   #here -1 means this data has been marked repeated one, no scan again later
          $d_flag[$k]=-1;   #here -1 means this data has been marked repeated one, no scan again later
          $d_rpt_cmte_id[$i]=$d_cmte_id[$k];
          $d_rpt_name[$i]=$d_name[$k];
          $d_rpt_zip[$i]=$d_zip[$k];
          $d_rpt_date_transaction[$i]=$d_date_transaction[$k];
          $d_rpt_amt_transaction[$i]=$d_amt_transaction[$k]; 
          $d_rpt_year[$i]=substr($d_rpt_date_transaction[$i],4,4);  #transaction year
          print REPEAT  "$d_rpt_cmte_id[$i]|$d_rpt_name[$i]|$d_rpt_zip[$i]|$d_rpt_date_transaction[$i]|$d_rpt_amt_transaction[$i]\n";
          print "$d_rpt_cmte_id[$i]|$d_rpt_name[$i]|$d_rpt_zip[$i]|$d_rpt_date_transaction[$i]|$d_rpt_amt_transaction[$i]\n";


          $i++;
        }#end if(($d_name[$j] eq $d_name[$k]) and ($d_zip[$j] eq $d_zip[$k]))

      }#end for ($k=($j+1);$k<=$#d_cmte_id;$k++)

    }#end if($d_other_id[$j]==1) #valid data or data has not been marked as repeat one
    else  #OTHER_ID is not empty (0) or labeled repeated one (-1), skip this data while searching repeated donators
    {next;}

  }#end for ($j=1;$j<$#d_cmte_id;$j++)

  $amt_repeat_donor_rec=$i;

  #save unique cmte_id, zip, and year to arrays for later group calculations
  for($i=0;$i<=$#d_rpt_cmte_id;$i++)
  {
    #save unique 
    if($i==0)
    {
      $d_grp_uniq_cmte_id[0]=$d_rpt_cmte_id[$i];
      $d_grp_uniq_zip[0]=$d_rpt_zip[$i];
      $d_grp_uniq_year[0]=$d_rpt_year[$i];
    }#end if($i==1)
    else  #search duplicated record, if not find, save into the related array
    {
      $j=0;
      foreach $_ (@d_grp_uniq_cmte_id)
      {
        chomp($_);
        if($_ ne $d_rpt_cmte_id[$i]){$j++;next;}
        else{last;}
      }
      if($j>$#d_grp_uniq_cmte_id){push @d_grp_uniq_cmte_id, $d_rpt_cmte_id[$i];}

      $j=0;
      foreach $_ (@d_grp_uniq_zip)
      {
        chomp($_);
        if($_ ne $d_rpt_zip[$i]){$j++;next;}
        else{last;}
      } 
      if($j>$#d_grp_uniq_zip){push @d_grp_uniq_zip,$d_rpt_zip[$i];}
     
    }#end else of if($i==0)

  }#end for($i=0;$i<=$#d_rpt_cmte_id;$i++)


  #sort amt data
  #calculate percentile
  @d_srt_amt_transaction=sort{ $a <=> $b } @d_rpt_amt_transaction;
  my $rank;
  $rank=($percentile_value/100)*$#d_srt_amt_transaction;
  print colored("rank $rank\n","bold yellow");





  # calculate total donator amount based on cmte_id, zip, and year
  $i=0;$j=0;
  foreach $grp_id (@d_grp_uniq_cmte_id)
  {
    foreach $grp_zip (@d_grp_uniq_zip)
    {
      for ($i=0;$i<$amt_repeat_donor_rec;$i++)
      {
#print"$i $d_rpt_amt_transaction[$i]($grp_id eq $d_rpt_cmte_id[$i] and $grp_zip eq $d_rpt_zip[$i] and $d_rpt_target_year eq $d_rpt_year[$i] and $d_flag[$i]==-1)\n";
        if($grp_id eq $d_rpt_cmte_id[$i] and $grp_zip eq $d_rpt_zip[$i] and $d_rpt_target_year eq $d_rpt_year[$i] and $d_flag[$i]<=0)
        {
          $d_rpt_count[$j]=0 unless defined $d_rpt_count[$j];
          $d_rpt_count[$j]++;
          $d_rpt_amt_total[$j]=0 unless defined $d_rpt_amt_total[$j];
          $d_rpt_amt_total[$j]=$d_rpt_amt_total[$j]+$d_rpt_amt_transaction[$i];
          print CAL "$grp_id|$grp_zip|$d_rpt_target_year|$d_rpt_amt_transaction[$i]|$d_rpt_amt_total[$j]|$d_rpt_count[$j]\n";
          print "$grp_id|$grp_zip|$d_rpt_target_year|$d_rpt_amt_transaction[$i]|$d_rpt_amt_total[$j]|$d_rpt_count[$j]\n";
        }
        else
        {next;} 
      }#end for ($i=1;$i<=$amt_repeat_donor_rec;$i++)
    }#end foreach $grp_zip (@d_grp_uniq_zip)
  
    $j++;
  }#end foreach $grp_id (@d_grp_uniq_cmte_id)
  
  close(REPEAT);
  close(RAW);
  close(INVALID);
  close(CAL);



}#end if($flag==1)

print "\n";

## write commands to command file for record
my $datelog=`date`;
$datelog=tm::trim($datelog);
system("echo '$datelog  $SCRIPT_NAME' >> command");   #if running this script, write it into command for record


### subroutine/function
sub leapyear
{       
  my ($sub_line)=($_);
  my $leap_flg;
  chomp($sub_line);
  if($d_year%4 == 0)
  {
    if($d_year%100 ==0)
    {
      if($d_year%400==0)
      {$leap_flg=1;}
      else
      {$leap_flg=0;}
    }
    else
    {$leap_flg=1;}
  }
  else
  {$leap_flg=0;}
  return $leap_flg;

}


