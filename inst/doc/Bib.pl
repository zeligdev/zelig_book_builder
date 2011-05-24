
# set a file handle to the appropriate position
sub specify_position {

  my ($handle, $position) = @_;

  # get/specify file handle position
  if (defined $position) {
    seek $handle, $position, 0;
  }
  else {
    $position = tell $handle;
  }

  $position
}

# Find the Position of 'needle'
# return the position of needle
sub find_char {
  my ($handle, $needle, $position) = @_;

  $position = specify_position $handle, $position;

  for (my $k=0; my $char = getc $handle; $k++) {
      return $position + $k if $char eq $needle;
  }

  -1;
}

# Return start and end position for matched section
sub match_brace {
  my ($handle, $open, $close, $position) = @_;

  $open = '{' unless defined $open;
  $close = '}' unless defined $close;
  
  $position = specify_position $handle, $position;
  
  return ($position, $position) if ($open eq $close);
  
  my $open_pos = find_char $handle, $open;

  $level = 1;

  my $end_pos = $position;

  # ...
  while ($level > 0 && ! eof $handle) {
    $next_char = getc $handle;
    if ($next_char eq $open) {
      $level++;
    }
    elsif ($next_char eq $close) {
      $level--;
    }

    $end_pos++;
  }

  #
  ($position, $end_pos);
}

sub get_chunk {

  my ($handle, $position) = @_;

  return undef if eof $handle;

  $position = tell $handle;

  my $start = find_char $handle, '@';
  my $first_brace = find_char $handle, '{', $start;
  my $first_paren = find_char $handle, '(', $start;


  my ($opener, $close, $open_pos, $close_pos);

  if ($first_paren == -1 || $first_brace < $first_paren) {
    $opener = '{';
    $closer = '}';
    $open_pos = $first_brace;
  }
  else {
    $opener = '(';
    $closer = ')';
    $open_pos = $first_paren;
  }
  my ($open, $close) = match_brace $handle, $opener, $closer, $open_pos;

  my ($type, $title, $block);

  return undef if ($open - $start - 1 <= 0);

  seek $handle, $start+1, 0;
  read $handle, $type, $open-$start-1;

  return undef if ($close - $open - 1 <= 0);

  seek $handle, $open+1, 0;
  read $handle, $block, $close-$open-1;

  my $first_comma = index $block, ',';


  if ($first_comma < 0) {
    return undef;
  }

  my $title = substr $block, 0, $first_comma;
  $block = substr $block, $first_comma+1;

  {key => $type, title => $title, body => $block}
}

my $dest = $ARGV[0];

open DEST, ">$dest" or die "Could not open file: \"$dest\"";

my %results;

foreach $k (1 .. $#ARGV) {

  my $file = $ARGV[$k];

  next if ( ! -e $file);

  open FI, "<$file";

  my $entry;


  while ($entry = get_chunk(FI), defined $entry) {
    my $title = $entry->{title};
    $results{$title} = $entry;
  }

  close FI;

}

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}


for my $key (keys %results) {
  my $entry_key = trim($results{$key}->{key});
  my $entry_title = trim($results{$key}->{title});
  my $entry_body = trim($results{$key}->{body});

  print DEST <<ENTRY_FORMAT;
\@$entry_key\{$entry_title,
  $entry_body
}
ENTRY_FORMAT
}


close DEST;
