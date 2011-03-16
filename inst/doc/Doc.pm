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

  #my $slash = $/;
  #$/ = \0;

  my @files = <FI> =~ m/\\includegraphics{(?:.*)}/gs;
  #$string =~ s/^\s+//;
  #$string =~ s/\s+$//;

  # trim whitespace
  @graphics = map {  
    $_ =~ s/^\s+//;
    $_ =~ s/\s+$//;
    $_
  } @files;

  @graphics;
}


=item link()

  link
  return:

=cut
sub copy_links {

  my ($self, $to) = @_;
  my @includes = $self->get_included_graphics();
  my $file = $self->get_full_path();


  # symbolic link included files
  for (@includes) {
    my $base = basename($_);
    symlink $_, "$to/$base";
  }

  # symlink actual file
  symlink $file, "$to/" . basename($file);
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
  ($/, $slash) = ($slash, $/);

  open FI, "<" . $self->get_fullpath()
    or die("could not open Doc $self->{_file} file");

  if (<FI> =~ m/\\begin{document}(.*?)\\end{document}/s) {
    close FI;
    $/ = $slash;
    return $1;
  }
  
  $/ = $slash;
  close FI;
  return <FI>;
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
  my @titles = <FI> =~ m/\\title\{(.*?)}/g;

  $/ = $slash;
  close FI;

  my $result = pop @titles;

  defined $result ? $result : "";
}



package DocTools;

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
  my $tmp_dir = tempdir("make_docs_XXXX");
  my ($handle, $tmp_file) = tempfile("Zelig_XXXX", DIR => $tmp_dir);

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
             _temp_file => $tmp_file,
             _temp_handle => $handle,

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

  @packages = $self->get_packages();

  print $handle "\\documentclass{book}\n\n";
  print $handle "% packages\n";
  print $handle join "\n", map { "\\usepackage{$_}" } @packages;
  print $handle "\n\n";
  print $handle "\\begin{document}\n\n";

  for (@{$self->{_parts}}) {
    $_->write($handle, $self->{_file})
  }

  print $handle q/\end{document}/;

  close $handle;
}


=item setup_env()

  creates a temporary directory to build the book

=cut
sub setup_env {
  my $self = shift;

  my $tmp_dir = $self->{_temp_dir};
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

      push @packages, @{[ $doc->get_packages() ]};

      $newfile = File::Spec->catfile($tmp_dir, $doc->get_file_name());

      open FI, ">$newfile";
      print FI $doc->get_body();
      $doc->{_dir} = $tmp_dir;
      close FI;
      $chapter->{_dir_name} = $tmp_dir;
    }
  }
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


1;
