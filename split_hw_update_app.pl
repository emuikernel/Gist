#!/usr/bin/perl
######################################################################
#
#   File          : split_updata.pl
#   Author(s)     : McSpoon
#   Description   : Unpack a Huawei U8220 'UPDATA.APP' file.
#                   http://pulse.modaco.com
#
#   Last Modified : Thu 24 December 2009
#   By            : McSpoon
#
######################################################################

use strict;
use warnings;

# Turn on print flushing.
$|++;

# Unsigned integers are 4 bytes.
use constant UINT_SIZE => 4;

# If a filename wasn't specified on the commmand line then
# assume the file to be unpacked is called "UPDATA.APP". 
my $FILENAME = undef;
if ($#ARGV == -1) {
	$FILENAME = "UPDATA.APP";
}
else {
	$FILENAME = $ARGV[0];
}

open(INFILE, $FILENAME) or die "Cannot open $FILENAME: $!\n";
binmode INFILE;

# Skip the first 92 bytes, they're blank.
seek(INFILE, 92, 0);

# We'll dump the files into a folder called "output".
my $BASEPATH = "output/";
mkdir $BASEPATH;

# These filenames are guessed. Feel free to correct.
&dump_file($BASEPATH."file01.mbn");
&dump_file($BASEPATH."file02.mbn");
&dump_file($BASEPATH."boot_versions.txt");
&dump_file($BASEPATH."file04.mbn"); # oemsblhd.mbn?
&dump_file($BASEPATH."file05.mbn"); # oemspl.mbn?
&dump_file($BASEPATH."upgradable_versions.txt");
&dump_file($BASEPATH."file07.mbn"); # 40byte header
&dump_file($BASEPATH."file08.mbn"); # .ELF, AMSS?
&dump_file($BASEPATH."file09.mbn");
&dump_file($BASEPATH."version.txt");
&dump_file($BASEPATH."file11.mbn");
&dump_file($BASEPATH."appsboothd.mbn"); # 40byte header
&dump_file($BASEPATH."appsboot.mbn");
&dump_file($BASEPATH."file14.mbn"); # 40byte header
&dump_file($BASEPATH."boot.img");
&dump_file($BASEPATH."file16.mbn"); # 40byte header
&dump_file($BASEPATH."system.img");
&dump_file($BASEPATH."file18.mbn"); # 40byte header
&dump_file($BASEPATH."userdata.img"); # maybe?
&dump_file($BASEPATH."file20.mbn"); # 40byte header
&dump_file($BASEPATH."file21.mbn"); # 40byte header
&dump_file($BASEPATH."recovery.img");
&dump_file($BASEPATH."file23.mbn"); # 40byte header
&dump_file($BASEPATH."splash.raw565"); # 320x480 raw pixels in RGB_565
&dump_file($BASEPATH."file25.mbn");
close INFILE;


# Unpack a file block and output the payload to a file.
sub dump_file {
    my ($outfilename) = @_;
    my $buffer = undef;

    # Verify the identifier matches.
    read(INFILE, $buffer, UINT_SIZE);
    unless ($buffer eq "\x55\xAA\x5A\xA5") {
		die "Unrecognised file format. Wrong identifier.\n";
    }
    
    # Extract the packet length.
    read(INFILE, $buffer, UINT_SIZE);
    my ($packetLength) = unpack("V", $buffer);
    
    # Ignore the next 16 bytes.
    read(INFILE, $buffer, 16);
    
    # Extract the length of the data file.
    read(INFILE, $buffer, UINT_SIZE);
    my ($dataLength) = unpack("V", $buffer);
    
    # Ignore the rest of the packet. We've already read the first 28 bytes.
    read(INFILE, $buffer, $packetLength-28);
    
    # Dump the payload.
    read(INFILE, $buffer, $dataLength);
    open(OUTFILE, ">$outfilename") or die "Unable to create $outfilename: $!\n";
    binmode OUTFILE;
    print OUTFILE $buffer;
    close OUTFILE;
    
    # Ensure we finish on a 4 byte boundary alignment.
    my $remainder = UINT_SIZE - (tell(INFILE) % UINT_SIZE);
    if ($remainder < UINT_SIZE) {
    	# We can ignore the remaining padding.
    	read(INFILE, $buffer, $remainder);
    }
    
    print STDOUT "Extracted $outfilename\n";
}

