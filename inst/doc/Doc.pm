package Doc;



=head1 NAME

LaTeX::Doc

=head1 SYNOPSIS

  use LaTeX::Doc;
  doc = new LaTeX::Doc FILE;

=cut


use File::Temp qw/ tempdir tempfile /;
use File::Basename;
use File::Spec;
use List::MoreUtils qw/ uniq /;


=head1 METHODS

=over 2

=item new Doc(file => "file_name")

  param: file a character string specifying a file name
  return: a LaTeX::Doc object

=cut

sub new {
  my ($class, %hash) = @_;

  my $file_name = $hash{file};
  my $hard_link = $hash{link};
  my $dir_name = $hash{dir};
  my $suffix;

  # add error-checking here
  # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
  unless (defined $dir_name) {
    ($file_name, $dir_name, $suffix) = File::Basename::fileparse($file_name);
  }

  $file_name = "$file_name.tex" unless $file_name =~ m/\.tex$/;
  $dir_name = "$dir_name/" unless $dir_name =~ m/.\/$/;

  my $full_path = File::Spec->catfile($dir_name, $file_name);
  my $abs_path = File::Spec->rel2abs($full_path);

  # define
  my $self = {
    _file => $file_name,
    _dir => $dir_name,
    _link => $hard_link,
    _suffix => $suffix,
    _fullpath => $full_path,
    _abspath => $abs_path
  };

  bless $self, $class;
}


=item DESTROY

  deconstructor

=cut

sub DESTROY {
}


=item get_fullpath()

  return: fullpath

=cut
sub get_fullpath {
  my $self = shift;
  $self->{_fullpath};
}

=item get_abs_path()

  return: absolute path to file

=cut

sub get_abs_path {
  my $self = shift;
  File::Spec->rel2abs($self->get_fullpath())
}

=item get_file_name()

  return: file name

=cut
sub get_file_name {
  my $self = shift;
  $self->{_file}
}

=item get_dir()

  return: directory

=cut
sub get_dir {

  my $self = shift;
  $self->{_dir};
}

=item get_includegraphics()

  return: get all the included graphics

=cut
sub get_included_graphics {
  my ($self) = @_;
  my $file = $self->get_fullpath();

  open FI, "<$file" or die();

  my $slash = $/;
  $/ = \0;

  my @files = <FI> =~ m/\\includegraphics\{(.*)\}/g;

  # trim whitespace
  @graphics = map {  
    $_ =~ s/^\s+//;
    $_ =~ s/\s+$//;
    $_
  } @files;

  $/ = $slash;

  @graphics;
}


=item link()

  link
  return:

=cut
sub copy_links {

  my ($self, $to) = @_;
  my @includes = $self->get_included_graphics();
  my $file = $self->get_fullpath();


  # symbolic link included files
  for (@includes) {
    for my $file_name (DocTools::list_graphics($_)) {
      DocTools::link_to($file_name, $to);
    }
  }

  my $dots = File::Spec->catdir( ('..') x DocTools::path_length($to));
  my $end_file = File::Spec->catfile($dots, $file);

  # symlink actual file
  #symlink $end_file, File::Spec->catfile($to, basename($file));
  #"$to/" . basename($file);
}


=item get_packages()

  return: list of packages used in document

=cut
sub get_packages {
  my ($self, %params) = @_;

  my $file = $self->get_fullpath();

  open FI, "<" . $self->get_fullpath()
    or die("could not open Doc $self->{_file} file");


  my $old_slash = $/;
  $/ = \0;

  my @packages = <FI> =~ m/[^%](\\usepackage(?:\[.*?\])?{.*?}(?:\[.*?\])?)/gs;

  close FI;

  $/ = $old_slash;

  my @results = map { /\\usepackage(\[.*?\])?{(.*?)}/; "$2" } @packages;

  @results;
}


=item get_body()

  gets all text between \begin{document} ... \end{document}, or
  returns entire document as a string
  return: the body text of the document

=cut
sub get_body {
  my ($self, %params) = @_;

  my $slash = \0;
  my $body;
  ($/, $slash) = ($slash, $/);

  open FI, "<" . $self->get_fullpath()
    or die("could not open Doc $self->{_file} file");


  <FI> =~ m/\\begin{document}(.*?)\\end{document}/s;

  if (length $1 == 0) {
    # if the string is empty, then
    # reopen file-handle
    close FI;
    open FI, "<" . $self->get_fullpath()
      or die("could not open Doc $self->{_file} file");
    $body = <FI>;
  }
  else {
    # otherwise we got the correct value
    $body = $1;
  }


  close FI;
  $/ = $slash;

  return DocTools::strip_bib($body);
}

=item get_bibstyle()

  gets information on the bibstyle
  return: a string specifying the bibstyle, or the first
          in case of multiples

=cut
sub get_bibstyle {
  my ($self) = @_;

  my $slash = $/;

  ($/, $slash) = (\0, $/);

  open FI, "<" . $self->get_fullpath()
    or die("could not open Doc $self->{_file} file");

  my @bibs;
 
  @bibs = <FI> =~ m/\\bibliographystyle{(.*?)}/gs;
   
  close FI;

  $/ = $slash;
  uniq @bibs;
}

=item get_bibliographies()

  return: a list of bibliography files required by the package

=cut
sub get_bibliographies {
  
  my ($self, %params) = @_;

  my $slash = $/;

  ($/, $slash) = (\0, $/);

  open FI, "<" . $self->get_fullpath()
    or die("could not open Doc $self->{_file} file");


  my @bibs;
 
  @bibs = <FI> =~ m/\\bibliography{(.*?)}/gs;
  @bibs = map { split /\s*,\s*/, $_ } @bibs;

   
  close FI;

  $/ = $slash;
  return @bibs;
  my $result = pop @bibs;
  defined $result ? $result : "";
}

=item get_file_location()

  return: location of file

=cut
sub get_file_location {
  my $self = shift;

  $self->{file}
}


=item get_title()

  get title of TeX document
  param: ..1 a blob of text
  return: content of the title tags in the block of text

=cut
sub get_title {
  my $self = shift;

  open FI, "<" . $self->get_fullpath()
    or die("could not open Doc $self->{_file} file");;

  my $slash = $/;
  $/ = \0;
  my @titles = <FI> =~ m/\\title\{(.*?)}/gs;

  $/ = $slash;
  close FI;


  my $result = pop @titles;

  $result =~ s/\s+/ /g;
  $result =~ s/^ +//g;
  $result =~ s/ +$//g;

  defined $result ? $result : "";
}

package DocTools;

use File::Basename qw/ basename dirname /;
use File::Spec;
use File::Path qw/ mkpath /;

our @graphic_exts = ('eps', 'pdf', 'jpg', 'gif', 'png');
our @doc_exts = ('tex');


=item link_doc( FILE_NAME, TO )

  param FILE_NAME: a character-string specifying a file
  param TO: a character-string specifying the destination directory
  return: under

=cut
sub copy_links {
  my ($file, $to) = @_;
  my $doc = new Doc(file => $file);

  $to = "." unless defined $to;

  print DocTools::path_length $to;

  $doc->copy_links($to);

  my $dots = File::Spec->catdir( ('..') x DocTools::path_length($to));
  my $end_file = File::Spec->catfile($dots, $file);

  symlink $end_file, File::Spec->catfile($to, basename($file));
}

=item path_length($dir)

  ...

=cut
sub path_length {
 scalar File::Spec->splitdir(shift);
}

sub find_graphic {
  
  my $name = shift;

  for (@graphic_exts) {
    my $file = "$name.$_";

    return $file if -e $file;
  }

  undef;
}

sub list_graphics {

  my $name = shift;
  my @hits;

  for (@graphic_exts) {
    my $file = "$name.$_";
    push @hits, $file if -e $file;
  }
  
  @hits;
}

=item ...

  waiting by the phone

=cut
sub link_to {

  my ($target, $into) = @_;

  my $base = basename $target;
  my $dir = dirname $target;

  my $path = File::Spec->catdir($into, $dir);
  my $dest = File::Spec->catfile($path, $base);
  my $diff = scalar File::Spec->splitdir($path);

  mkpath $path;

  $target = File::Spec->catdir( ('..') x $diff , $target);

  symlink $target, $dest;
}

=item swap($left, $right)

  switches the values of $left and $right

=cut
sub swap {
  (${\$_[1]}, ${\$_[0]}) = @_;
}


=item blah()

  lies

=cut
sub strip_bib {

  my $text = shift;

  # strip nobibliography commands
  $text =~ s/\\nobibliography\*?\n?//g;

  # strip bibliography specifications
  $text =~ s/\\bibliography\{.*?\}//gs;

  # strip bibliography style specifications,
  # then return
  $text =~ s/\\bibliographystyle\{.*?\}//gs;

  $text;
}

# @_: list of arguments as an array
# result - a list with unique entries
sub uniq {
  my $hits = {};
  grep { ! $hits->{$_}++ } @_;
}

# compares two dates, used for sorting lists of strings
# param: $a a string formatted like dd/dd/dddd
# param: $b ta string formatted like dd/dd/ddd
# return: -1, 0, 1 - less than, equal, greater than
sub date_cmp {
  # convert left hand side into a triplet of numbers
  $a =~ /(\d?\d)\/(\d?\d)\/(\d{4})/;
  my ($lmon, $lday, $lyear) = ($1, $2, $3);

  # convert right hand side into ... """
  $b =~ /(\d?\d)\/(\d?\d)\/(\d{4})/;
  my ($rmon, $rday, $ryear) = ($1, $2, $3);

  # compare
  return $lyear <=> $ryear unless $lyear == $ryear;
  return $lmon <=> $rmon unless $lmon == $rmon;
  $lday <=> $rday;
}


# reduces a list of packages to unique entries
# params: @_ a list of package preamble commands
# return: a reduced list - containing only the earliest dated
#         of each package
# future: allow to set an option that can choose between
#         earliest and oldest package
sub reduce_packages {
  my @packages;
  my @package_names = uniq map { m/\\usepackage{(.*?)}/ } @_;

  for (@package_names) {
    # generate regex
    my $regex = qr{\\usepackage{$_}\[(.*?)\]};

    # sort list of dates and get earliest
    my @dates = sort { &date_cmp } map { m/$regex/ } @_;

    my $date = shift @dates;

    # construct earliest dated package
    my $pack = q/\usepackage/;
    $pack .= "{$_}";
    $pack .= "[$date]" if defined $date;

    push @packages, $pack;
  }

  @packages;
}



#
#
package Book;

use File::Temp qw/ tempfile tempdir /;
use File::Spec;

sub new {

  my ($self, %params) = @_;


  my $title = $params{title};
  my $tmp_dir = ""; #tempdir("make_docs_XXXX");
  #my ($handle, $tmp_file) = tempfile("Zelig_XXXX", DIR => $tmp_dir);

  my $obj = {
             _file => $params{file},
             _FILE => $handle,
             _title => $params{title},
             _authors => $params{authors},
             _parts => [],
             _part_order => {},

             # temporary environment stuff
             #   this manages where hard links, etc.
             #   are located during the build process
             _temp_dir => $tmp_dir,
             #_temp_file => $tmp_file,
             #_temp_handle => $handle,

             # dependency management stuff
             _packages => [],
             _commands => [],
             _styles => [],
             _bibs => []
  };

  bless $obj, $self;
}



sub add_parts {
  my ($self, @parts) = @_;
  my @packages, @styles, @bibs, @commands;

  for (@parts) {
    push @{$self->{_parts}}, $_;
  }

}

sub bibliographies {
  my ($self, @bibs) = @_;
  push @{$self->{_bibs}}, DocTools::uniq @bibs;
  return @{$self->{_bibs}};
}


=item write_book(to_file => T/F)

  param: to_file boolean. determines whether the book is
         printed into a temporary environment, rather than
         standard output
  return: none

=cut
sub write_book {
  my $self = shift;
  my $handle;

  open $handle, ">$self->{_file}";

  my @packages = DocTools::uniq @{$self->{_packages}};

  print $handle "\\documentclass{book}\n\n";
  print $handle "% packages\n";
  print $handle join "\n", map { "\\usepackage{$_}" } @packages;
  print $handle "\n\n";
  print $handle "\\begin{document}\n\n";

  for (@{$self->{_parts}}) {
    $_->write($handle, $self->{_file})
  }

  my $bib_string = join ",", @{$self->{_bibs}};
  $bib_string = qq/\\bibliography{$bib_string}/;

  print $handle "$bib_string\n";
  print $handle q/\bibliographystyle{plain}/;
  print $handle q/\end{document}/;

  close $handle;

  print $self->get_bibs();
}

=item 

  ...

=cut
sub get_bibs {
  my $self = shift;
  my @bibs;

  foreach ($self->list_docs()) {

    push @bibs, $_->get_bibliographies();

  }
  print "=================\n";
  print join "\n", @bibs;
  print "----------------\n\n";
  DocTools::uniq @bibs;
}


=item list_docs()

  stick and move

=cut
sub list_docs {
  my $self = shift;
  my @docs;

  for $part (@{$self->{_parts}}) {
    for $chapter (values %{$part->{_chapters}}) {
      my $doc = $chapter->as_doc();
      push @docs, $doc;
    }
  }

  @docs;
}


=item copy_includes($to_file)

  

=cut
sub copy_includes {
  my ($self, $to)  = @_;
  my @docs = $self->list_docs();

  $to = '.' unless defined $to;

  for (@docs) {
    $_->copy_links($to);
  }

}


=item setup_env()

  creates a temporary directory to build the book

=cut
sub setup_env {
  my ($self, $to) = @_;

  my $tmp_dir = $to;
  my $tmp_file = $self->{_temp_file};

  my @packages = ();

  print << "TEMP";
Building Temporary Environment
 Directory ....... $tmp_dir
 TeX Document .... $tmp_file

Linking Files
TEMP
  for my $part (@{ $self->{_parts} }) {

  
    for my $chapter (values %{ $part->{_chapters} }) {
      my $doc = $chapter->as_doc();

      print $doc->get_fullpath(), "\n";

      push @packages, @{[ $doc->get_packages() ]};

      $newfile = File::Spec->catfile($tmp_dir, $doc->get_file_name());

      print "> $newfile \n";

      # have to store it in a local variable
      # might be best done via a FILE handle
      my $body = $doc->get_body();

      $body = DocTools::strip_bib $body;

      open FI, ">$newfile" or die "well that was a waste of time";
      
      print FI $body;
      
      #$doc->{_dir} = $tmp_dir;
      
      close FI;

      #$chapter->{_dir_name} = $tmp_dir;
    }
  }

  $self->{_packages} = [ @packages ];
}


=item get_packages()

  return: a list of all the packages from all the articles
          composing the book

=cut
sub get_packages {

  my $self = shift;
  my @packages = ();

  for (@{$self->{_parts}}) {
    push @packages, $_->get_packages();
  }

  return @packages;
}


# end
sub get_temp_dir {
  shift()->{_temp_dir};
}


package Part;


sub new {
  my ($class, $title) = @_;

  my $self = {
              _chapters => {},
              _order => [],
              _title => $title
  };

  bless $self, $class;
}

# title
sub set_title {
  my ($self, $title) = @_;

  $self->{_title} = $title;
}


# key-value pair style submission
sub add_chapters {
  my ($self, %params) = @_;

  map {

    # add file to list
    $self->{_chapters}->{$_} = $params{$_};

    # maintain order
    push @{$self->{_order}}, $_;

  } keys %params;

}


# write part as a TeX file
#
#
sub write {
  my ($self, $handle, $dest) = @_;
  my $title = $self->{_title};

  if (defined $title) {
    print $handle q/\part{/, $title, "}\n";
    print $handle q/\label{part:/, $title, "}\n\n";
  }

  for (values %{$self->{_chapters}}) {
    $_->print_as_include($handle, $dest);
    print $handle "\n";
  }
}

=item get_packages()

  return: listed packages

=cut
sub get_packages {

  my $self = shift;
  my @packages = ();

  for (keys %{$self->{_chapters}}) {

    my $doc = new Doc(file => $_);
    push @packages, $doc->get_packages();
  }

  @packages;
}


package Chapter;

use File::Basename qw/ basename dirname /;

sub new {
  my ($class, $file_name, $chapter_name, $short_name) = @_;

  $filename = File::Basename::basename($file_name, ".tex");
  $basename = File::Basename::dirname($file_name);

  $chapter_name =~ m/(.*?):.*/;
  $short_name = ucfirst lc $1;

  my $self = {
    _file_name => $filename,
    _dir_name => $basename,
    _chapter_name => defined $chapter_name ? $chapter_name : $file_name,
    _short_name => defined $short_name ? $short_name : undef
  };

  bless $self, $class;
}

sub as_doc {

  my $self = shift;


  new Doc(
    file => $self->{_file_name},
    dir => $self->{_dir_name}
  );
}

sub print_as_include {
  my ($self, $handle, $dest) = @_;

  $handle = STDOUT unless defined $handle;
  #
  my $chapter_name = $self->{_chapter_name};
  my $label = $self->{_short_name};
  
  my $doc = $self->as_doc();
  # ...
  $label = $self->{_file_name} if not defined $label;

  my ($file_name) = $doc->get_abs_path();

  $dest = File::Spec->rel2abs($dest);
  #print " > ", dirname $dest, "\n\n";

  $file_name = File::Spec->abs2rel($file_name, dirname $dest);
  $file_name = basename($file_name);
  ($file_name) = $file_name =~ m/(.*)\.tex$/;

  print $handle q/\chapter/;
  print $handle "[$self->{_short_name}]" if defined $self->{_short_name};
  print $handle "{$chapter_name}\n";
  print $handle "\\label{chapter:$label}\n";
  print $handle q/\input{/, $file_name, "}\n";
}

# CONF TOOLS
package DocRegexes;

use strict;
use warnings;

# {part name}
our $part = qr/^\{(.*?)\}$/;

# ***
our $appendix = qr/^\*\*\*$/;

# *file name
our $chapter_wo_file = qr/^\*\s*(.*)$/;

# :chapter name
our $title = qr/^:(.*)$/;

# file: chapter name
our $chapter = qr/(.*?):(.*)/;

# hard links
our $link = qr/\[(.*?)\]/;

our $bib = qr//;

our $bibstyle = qr//;

our $nobib = qr/\\nobibliography\*?/;

1;
