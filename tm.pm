#use to trunck the last hidden symbol, like \n, and remove the redundent space at the beginning and end.
package tm;

use strict;
use warnings;
use sys_perl;

sub trim 
{
  my ($sub_line)=@_;
  chomp($sub_line);
  $sub_line=~s/^\s+|\s+$//g;
  return $sub_line;
}
1;
