#!/usr/bin/env perl

use strict;

sub collect_args();
sub crop_image();
sub debug_print($);
sub dumpall();
sub make_motivator();
sub print_help();

#
# makemotivator.pl (c) 2009-2015 by Konstantin Boyandin <konstantin@boyandin.com>
#
# Command-line tool using ImageMagick to construct motivator images in 750x600 (600x750) geometry
#
# $Id$
#

my %vars = (
	'comment' => 'This (de)motivator has been created with makemotivator.pl script by Konstantin Boyandin <konstantin@boyandin.com>. Some rights reserved.',
	'annotate' => '',
	'io' => 'landscape',
	'h' => '',
	't' => '',
	'fd' => '/usr/share/fonts/msttcorefonts',
	'wd' => '/tmp',
	'hf' => 'times.ttf',
	'tf' => 'arial.ttf',
	'af' => 'arial.ttf',
	'hfs' => 48,
	'tfs' => 18,
	'afs' => 16,
	'v' => 0,
	'size' => 1,
	'dpi' => 0
);

#
# Get command-line parameters; print help message if none
#

if ($#ARGV < 0) {
	print_help();
} else {
	collect_args();
	crop_image();
	make_motivator();
}

#
# Function
#

sub collect_args() {
	my ($k, $v) = ('', 0);
# Gather args
	foreach my $i (@ARGV) {
		if ($v) {
			$v = 0;
			$vars{$k} = $i;
		} elsif ($i =~ /^-(\?|H|v|hfs|tfs|afs|hf|tf|af|fd|wd|h|t|io|i|o|dpi|comment|annotate|size)$/) {
			$v = 1; $k = $1; $vars{$k} = '';
		} else {
			die("Unknown parameter: $i\n");
		}
	}
# Sanity check
	if (defined($vars{'?'})	|| defined($vars{'H'})) {
		print_help();
		exit(0);
	}
# Input file check	
	if (defined($vars{'i'})) {
		if ((-f $vars{'i'}) && (-r $vars{'i'})) {
			my $cmdline = "identify -format \"%w %h\" ${vars{'i'}}";
			my $imgdim = `$cmdline`; chomp($imgdim);
			if ($imgdim =~ /^(\d+) (\d+)$/) {
				$vars{'iw'} = int($1); $vars{'ih'} = int($2);
			} else {
				die("File ${vars{'i'}} isn't an image file\n");
			}
		} else {
			die("File ${vars{'i'}} doesn't exist or can't be read\n");
		}
	} else {
		die("No input image name specified\n");
	}
# Orientation check
	if ($vars{'io'} =~ /^(landscape|portrait)$/) {
		$vars{'io'} = ($1 eq 'landscape') ? 1 : 0;
	} else {
		die("Parameter '-io' may be set to either 'landscape' or 'portrair'\n");
	}
# Generating output file name, if none present
	if (!defined($vars{'o'})) {
		if ($vars{'i'} =~ /^(.*\/)?(.*)$/) {
			$vars{'o'} = "${1}motivator-$2";
		} else {
			die("Wrong filename, should not occur\n");
		}
	}
# Font directory exists and both fonts are specified
	if ((-d $vars{'fd'}) && (-r $vars{'fd'})) {
		$vars{'tf'} = "${vars{'fd'}}/${vars{'tf'}}";
		$vars{'hf'} = "${vars{'fd'}}/${vars{'hf'}}";
		$vars{'af'} = "${vars{'fd'}}/${vars{'af'}}";
		if (!(-f $vars{'hf'}) || !(-r $vars{'hf'})) {
			die("Header font file ${vars{'hf'}} doesn't exist or can't be read\n");
		}
		if (!(-f $vars{'tf'}) || !(-r $vars{'tf'})) {
			die("Term font file ${vars{'tf'}} doesn't exist or can't be read\n");
		}
		if (!(-f $vars{'af'}) || !(-r $vars{'af'})) {
			die("Annotation font file ${vars{'af'}} doesn't exist or can't be read\n");
		}
	} else {
		die("Font directory ${vars{'fd'}} doesn't exist or can't be read\n");
	}
# Working directory sanitizing	
	if (!(-d $vars{'wd'}) || !(-r $vars{'wd'}) || !(-r $vars{'wd'})) {
		die("Working directory ${vars{'wd'}} doesn't exist or can't be both read from and written to\n");
	}
# Font sizes sanitizing
	$vars{'hfs'} = int($vars{'hfs'}); 
	if ($vars{'hfs'} < 8) {
		$vars{'hfs'} = 8;
	}
	$vars{'tfs'} = int($vars{'tfs'}); 
	if ($vars{'tfs'} < 8) {
		$vars{'tfs'} = 8;
	}
	$vars{'afs'} = int($vars{'afs'}); 
	if ($vars{'tfs'} < 8) {
		$vars{'tfs'} = 8;
	}
# Size multiplier sanitizing
	$vars{'size'} = int($vars{'size'}); 
	if ($vars{'size'} < 1) {
		$vars{'size'} = 1;
	}
# Setting actual sizes
    $vars{'hfs'} *= $vars{'size'};
    $vars{'tfs'} *= $vars{'size'};
    $vars{'afs'} *= $vars{'size'};
    my ($igw, $igh) =  (750 * $vars{'size'}, 600 * $vars{'size'});
    my ($sigw, $sigh) =  (600 * $vars{'size'}, 450 * $vars{'size'});
    $vars{'borderthin'} = 2 * $vars{'size'};
    $vars{'borderthick'} = 71 * $vars{'size'};
# Temporary name creation
	$vars{'tmpnam'}	= sprintf("%s/motivator-%d-%d.png", $vars{'wd'}, time(), rand(1000000));
# Set working parms depending on orientation
	if ($vars{'io'}) { # landscape
		$vars{'wr'} = 4; $vars{'hr'} = 3; $vars{'sigw'} = $sigw; $vars{'sigh'} = $sigh; $vars{'scale'} = "${sigw}x${sigh}"; $vars{'igh'} = "$igh"; $vars{'igw'} = "$igw";
	} else { # portrait
		$vars{'hr'} = 4; $vars{'wr'} = 3; $vars{'sigw'} = $sigh; $vars{'sigh'} = $sigw; $vars{'scale'} = "${sigh}x${sigw}"; $vars{'igw'} = "$igh"; $vars{'igh'} = "$igw";
	}
# Set effective input name
	$vars{'ei'}	= $vars{'i'};
# Set selfname	
	$vars{'selfname'} = $0;
	if ($0 =~ /^(.*\/)?(.*)$/) {
		$vars{'selfname'} = $2;
	}
} # collect_args

sub print_help() {
	print <<EOM;
Developed by Konstantin Boyandin <konstantin\@boyandin.com> to generate motivational posters.
Requires:
  perl 5.8+
  ImageMagick 6.3+
THUS SCRIPT IS DISTRIBUTED WITH ABSOLUTELY NO WARRANTY OF ANY KIND. USE IT ON YOUR OWN RISK.

Usage:
$0 parameters
Parameters description:
    -? or -H
        Prints this help text.
	-i inputfilename
        Mandatory. Specify image file. Unless file proportions aren't 4:3 (or 3:4, depending on orientation), it will be cropped to meet this ratio.
    -o outputfilename
        Optional. Output file name. If omitted, 'motivator-' will be appended to input file name to produce output file name.
    -io imageorientation
        Optional. Desired image orientation, 'landscape' (750x600) or 'portrait' (600x750). Default: 'landscape'.
    -h text
        Optional. Header text. Default: none.
    -t text
        Optional. Term text. Default: none.
    -fd fontdir
        Optional. Directory the font files are located in. Default: '${vars{'fd'}}'.
    -wd workdir
        Optional. Directory used to store temporary files. Default: '${vars{'wd'}}'.
    -hf fontfilename
        Optional. Font file name used to write header. Default: ${vars{'hf'}}.
    -tf fontfilename
        Optional. Font file name used to write term. Default: ${vars{'tf'}}.
    -hfs fontsize
        Optional. Font size the header is written with. Default: ${vars{'hfs'}}.
    -tfs fontsize
        Optional. Font size the term is written with. Default: ${vars{'tfs'}}.
    -v verboselevel
        Optional. If 0, only fatal errors are displayed. If 1, the script is more talkative about what it's doing. Default: ${vars{'v'}}.
EOM
} # print_help

sub dumpall() {
	foreach my $k (keys(%vars)) {
		print "$k: " . $vars{$k} . "\n";
	}
}

#
# crop_image determines whether the input image fits desired ratio and if it does not, crops
# part of it into another input file ('tmpnam').
#
sub crop_image() {
# Calculate remnants	
	my $hrem = $vars{'ih'} % $vars{'hr'};
	my $wrem = $vars{'iw'} % $vars{'wr'};
# Calculate effective length
	my $ehs = int(($vars{'ih'} - $hrem) / $vars{'hr'});
	my $ews = int(($vars{'iw'} - $wrem) / $vars{'wr'});
	debug_print("Remnants: H $hrem, W $wrem; effective sizes: H $ehs, W $ews");
# If remnants are both zero and effective lengths are equal, leave
	if (($hrem == 0) && ($wrem == 0) && ($ehs == $ews)) {
		return; # nothing to do
	}
# Take the minimal effective length and calculate crop dimension
	my $emins = ($ehs <= $ews) ? $ehs : $ews;
	my $eh = $emins * $vars{'hr'};
	my $ew = $emins * $vars{'wr'};
# Compose crop command line and make the cropped file
	my $xofs = ($vars{'iw'} - $ew) >> 1;
	my $yofs = ($vars{'ih'} - $eh) >> 1;
	debug_print("Cropping $ew x $eh out of ${vars{'iw'}} x ${vars{'ih'}}, starting at $xofs : $yofs");
	my $cmdline = "convert -crop \"${ew}x${eh}+${xofs}+${yofs}\" \"${vars{'i'}}\" \"${vars{'tmpnam'}}\"";
	$vars{'rc'} = `$cmdline`;
	if ($vars{'rc'} ne '') {
		die("Cropping failed: ${vars{'rc'}}\n");
	}
	$vars{'ei'} =  $vars{'tmpnam'}
}

sub make_motivator() {
#
# Make the scaled image
#
	my $cmdline = "convert -scale \"${vars{'scale'}}\" \"${vars{'ei'}}\" \"${vars{'o'}}\"";
	$vars{'rc'} = `$cmdline`;
	if ($vars{'rc'} ne '') {
		die("Scaling failed: ${vars{'rc'}}\n");
	}
#
# Add border
#
	$cmdline = "mogrify -bordercolor black -border ${vars{'borderthin'}} -bordercolor white -border ${vars{'borderthin'}} -bordercolor black -border ${vars{'borderthick'}}x0 \"${vars{'o'}}\"";
	$vars{'rc'} = `$cmdline`;
	if ($vars{'rc'} ne '') {
		die("Adding border failed: ${vars{'rc'}}\n");
	}
#
# Write header, if any
#
	if ($vars{'h'} ne '') {
		$cmdline = "montage -geometry +0+0 -background black -fill white -font \"${vars{'hf'}}\" -pointsize \"${vars{'hfs'}}\" -label \"${vars{'h'}}\" \"${vars{'o'}}\" \"${vars{'o'}}\"";
#		$cmdline = "montage -geometry +0+0 -background black -fill white -font \"${vars{'hf'}}\" -gravity center -pointsize \"${vars{'hfs'}}\" -size \"${vars{'sigw'}}\" caption:\"${vars{'h'}}\" \"${vars{'o'}}\" \"${vars{'o'}}\"";
		$vars{'rc'} = `$cmdline`;
		if ($vars{'rc'} ne '') {
			die("Adding header failed: ${vars{'rc'}}\n");
		}
	}
#
# Write terms, if any
#
	if ($vars{'t'} ne '') {
		$cmdline = "montage -geometry +0+0 -background black -fill white -font \"${vars{'tf'}}\" -pointsize \"${vars{'tfs'}}\" -label \"${vars{'t'}}\" \"${vars{'o'}}\" \"${vars{'o'}}\"";
#		$cmdline = "montage -geometry +0+0 -background black -fill white -font \"${vars{'tf'}}\" -gravity center -pointsize \"${vars{'tfs'}}\" -size \"${vars{'sigw'}}\" caption:\"${vars{'t'}}\" \"${vars{'o'}}\" \"${vars{'o'}}\"";
		$vars{'rc'} = `$cmdline`;
		if ($vars{'rc'} ne '') {
			die("Adding term failed: ${vars{'rc'}}\n");
		}
	}
#
# Determine height and add the missing border
#
	$cmdline = "identify -format \"%h\" \"${vars{'o'}}\"";
	my $ch = `$cmdline`; chomp($ch);
	if ($ch !~ /^\d+$/) {
		die("Error determining image height\n");
	}
	$ch = int($ch);
	if ($ch < $vars{'igh'}) {
# Add missing border and crop resulting image
		my $ah = $vars{'igh'} - $ch;
		my $docrop = $ah % 2;
		if ($docrop) {
			$ah = ($ah + 1) >> 1;
		} else {
			$ah = $ah >> 1;
		}
# Add border		
		$cmdline = "mogrify -bordercolor black -border 0x$ah \"${vars{'o'}}\"";
		$vars{'rc'} = `$cmdline`;
		if ($vars{'rc'} ne '') {
			die("Adding border failed: ${vars{'rc'}}\n");
		}
# If necessary, crop image		
		if ($docrop) {
			$cmdline = "mogrify -crop \"${vars{'igw'}}x${vars{'igh'}}+0+0\" \"${vars{'o'}}\"";
			$vars{'rc'} = `$cmdline`;
			if ($vars{'rc'} ne '') {
				die("Cropping final image failed: ${vars{'rc'}}\n");
			}
		}
	} else {
# Add small border and scale resulting image
		$cmdline = "mogrify -bordercolor black -border 0x20 \"${vars{'o'}}\"";
		$vars{'rc'} = `$cmdline`;
		if ($vars{'rc'} ne '') {
			die("Adding border failed: ${vars{'rc'}}\n");
		}
		$cmdline = "mogrify -resize \"!${vars{'igw'}}x${vars{'igh'}}\" \"${vars{'o'}}\"";
		$vars{'rc'} = `$cmdline`;
		if ($vars{'rc'} ne '') {
			die("Resizing final image failed: ${vars{'rc'}}\n");
		}
	}
# Set the comment
	$cmdline = "mogrify -comment \"${vars{'comment'}}\" \"${vars{'o'}}\"";
	$vars{'rc'} = `$cmdline`;
	if ($vars{'rc'} ne '') {
		die("Setting image comment failed: ${vars{'rc'}}\n");
	}
# Set the DPI if explicitly set
	if ($vars{'dpi'} > 0) {
		$cmdline = "mogrify -units PixelsPerInch -density ${vars{'dpi'}} \"${vars{'o'}}\"";
		$vars{'rc'} = `$cmdline`;
		if ($vars{'rc'} ne '') {
			die("Setting DPI failed: ${vars{'rc'}}\n");
		}
	}
# Annotate if necessary
	if ($vars{'annotate'} ne '') {
		$vars{'annotate'} .= ' ';
		$cmdline = "mogrify  -fill white -gravity southeast -font \"${vars{'af'}}\" -pointsize \"${vars{'afs'}}\" -annotate 0 \"${vars{'annotate'}}\" \"${vars{'o'}}\"";
		$vars{'rc'} = `$cmdline`;
		if ($vars{'rc'} ne '') {
			die("Annotating failed: ${vars{'rc'}}\n");
		}
	}
# Remove temporary file, if any
	if (-f $vars{'tmpnam'}) {
		unlink($vars{'tmpnam'});
	}
}

sub debug_print($) {
	my ($t) = @_;
	if ($vars{'v'} > 0) {
		print("${vars{'selfname'}}: $t\n");
	}
}