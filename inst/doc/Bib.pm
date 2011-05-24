package BibParser;

sub new {

  my ($class, $file) = @_;

  open $handle, 

  my $self = {
    _file => $file,
    _handle => $handle,
    _offset => 0
  };

  bless $self, $class;
}

sub next {

  my $self = shift;



}


sub get_next_key {

  my $pos = tell FI;
  
  

}






#
#
package BibEntry;

sub new {

  

};
