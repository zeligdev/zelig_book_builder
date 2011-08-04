#!/usr/bin/perl

# Builds the Documentation for Zelig
# requires
#  - zelig.book.builder (R package)
#  - LaTeX::Doc (perl package)
# author: Matt Owen
# date:   3/22/2011

use warnings;
use strict;

use Doc;
use File::Spec;


# splash screen
print << "INTRO";
e----------------+
| Make Docs v2.0 |
+----------------+

Document Builder for R-packages

INTRO


# COMMAND-LINE
# ************
my @single;
my $assign = {};

foreach (@ARGV) {
  my @splitted = split "=", $_;


  if (scalar(@splitted) == 1) {
    push @single, $_;
  }

  elsif (scalar(@splitted) == 2) {
    $assign->{$splitted[0]} = $splitted[1];
  }

  else {
    die "ERROR: incorrect number of parameters passed through commandline";
  }
}

# SETUP DEFAULTS
# **************
my $dest_file = defined $assign->{dest} ? $assign->{dest} : "doc.tex";
my $conf_file = defined $assign->{conf} ? $assign->{conf} : "order.conf";
my $dir = defined $assign->{dir} ? $assign->{dir} : "texs";
my $ws = defined $assign->{ws} ? $assign->{ws} : ".";

# output setup information
print << "INFO";
Summary
*******
 Destination File ..... $dest_file
 Configuration File ... $conf_file
 Directory ............ $dir

INFO



# FILE HANDLES
# ************

open DOC, ">$dest_file" or die("could not open `$dest_file' for writing");
open CONF, "<$conf_file" or die("could not open `$conf_file' for reading");

# BEGIN MAKING BOOK
# *****************

my $title = << "DOC";
  Zelig: Everyone's Statistical Software\\thanks{The current version of
  this software is available at 
  \\url{http://gking.harvard.edu/zelig}, free of charge and open-source
  (under the terms of the GNU GPL, v2)}
DOC

my $author = << "AUTHORS";
  Kosuke Imai\\thanks{Assistant Professor, Department of Politics,
  Princeton University
  (Corwin Hall, Department of Politics, Princeton University, Princeton NJ 08544;
  \\url{http://imai.princeton.edu/}, \\texttt{kimai\@princeton.edu})}
  \\and
  Gary King\\thanks{Albert J. Weatherhead III University Professor, Harvard
  University (Institute for Quantitative Social Sciences, 1737 Cambridge 
  Street, Harvard University, Cambridge MA 02138;
  \\texttt{http://gking.harvard.edu}, \\texttt{king\@harvard.edu},
  (617) 495-2027).}
  \\and
  Olivia Lau\\thanks{Ph.D. Candidate, Department of Government, Harvard
  University (1737 Cambridge Street, Cambridge MA 02138;
  \\texttt{http://www.people.fas.harvard.edu/\\~\\,olau},
  \\texttt{olau\@fas.harvard.edu}).}
AUTHORS

my $date = << "DATE";
\\today
DATE

my $tmp_dir = "";
my $book = new Book(
  title => $title,
  author => $author,
  file => "zelig.tex",
  date => $date
);




# ...
my $part = new Part("No one Ever Really Dies");
my $chapter;
my $doc = undef;

$tmp_dir = $book->get_temp_dir();
my @bibs;

print "\n\n\n\n\n\n\n";
print "***************************\n" x 4;
for my $line (<CONF>) {
  #
  chomp $line;


  # if it is a part
  if ($line =~ m/$DocRegexes::part/) {
    $part = new Part($1);
    $book->add_parts($part);
  }

  elsif ($line =~ m/$DocRegexes::link/) {
    print " * Linking:  '$dir/$1' to '$tmp_dir/$1'\n";
    symlink File::Spec->rel2abs($1), "$tmp_dir/$1";
  }

  # chapter with title explicitly set
  elsif ($line =~ m/$DocRegexes::chapter/) {
    $chapter = new Chapter("$dir/$1", $2);
    $part->add_chapters($1 => $chapter);
  }

  # chapter without title explicityly set
  elsif ($line =~ m/^[\w\\.]+$/) {
    print "$line\n";
    $doc = new Doc(file => "$dir/$line");
    my $title = $doc->get_title();

    push @bibs, $doc->get_bibliographies();

    my $short = $title;
    $short =~ s/:.*$//gs;

    $chapter = new Chapter(
                           "$dir/$line",
                           $doc->get_title(),
                           $short
                           );
    $part->add_chapters("$dir/$line" => $chapter);
  }

  # include file in the beginning
  elsif ($line =~ m/$DocRegexes::include/) {
  }

  elsif ($line =~ m/$DocRegexes::appendix/) {
  }
}
# add last part
$book->setup_env($dir);
$book->bibliographies(@bibs);


for my $fi ($book->list_docs()) {
  my $fullpath = $fi->get_fullpath();

  # symlink graphics, etc.
  $fi->copy_links($ws);

  # symlink actual file
  DocTools::copy_links($fullpath, $ws);
}

$book->write_book(to_file => 1);


# setup build environment
#$book->setup_env($ws);


close DOC;
close CONF;
