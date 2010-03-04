#########################################################################
# Filter()
#
# filters lines to correct syntax
#
# args: 1) infile - file to have words converted
# args: 2) outfile - file to output
#
#########################################################################
sub Filter {

	my $this = shift;
	my $args = {
		infile => " ",
		outfile => " ",
		@_,			# Override previous attributes
	};
	my $infile = $args->{infile};
	my $outfile = $args->{outfile};

        my @slashparts;
        my $filename;
	my @spaceparts;
        my $name;

        my $is_table = 0;

        open(INFILE, "<$infile");
        open(OUTFILE, ">$outfile");
        while (<INFILE>){

                ##########
                # line skips
                #
                next if /^----$/;       # remove unneeded header lines

                ##########
                # regexp substitutions
                #

                # list convert - 1st layer
                #
                s/^ \*(.*?)/\*$1/g;

                # list convert - 2nd layer
                #
                s/^  \*(.*?)/\*\*$1/g;

                # list convert - 3rd layer
                #
                s/^   \*(.*?)/\*\*\*$1/g;

                # list convert - 4th layer
                #
                s/^    \*(.*?)/\*\*\*\*$1/g;

                # list convert - 5th layer
                #
                s/^     \*(.*?)/\*\*\*\*\*$1/g;

                # list convert - numerical
                #
                s/^ 1.(.*?)/\#$1/g;

                # link convert - [[BR]] -> <br>
                #
                s/\[\[BR\]\]/\<br\>/g;

                # link convert superscripted - ^ * ^ -> <sup> * </sup>
                #
                s/\^(.*?)\^/\<sup\>$1\<\/sup\>/g;

                # link convert subscripted - ,, * ,, -> <sub> * </sub>
                #
                s/\,\,(.*?)\,\,/\<sub\>$1\<\/sub\>/g;

                # link convert smaller - ~- * -~ -> <small> * </small>
                #
                s/\~-(.*?)-\~/\<small\>$1\<\/small\>/g;

                # link convert larger - ~+ * +~ -> <big> * </big>
                #
                s/\~\+(.*?)\+\~/\<big\>$1\<\/big\>/g;

                # link convert - [# * ] -> [[ * ]]
                #
                s/\[\#(.*?)\]/\[\[\#$1\]\]/g;

                # link convert - [" * "] -> [[ * ]]
                #
                s/\[\"(.*?)\"\]/\[\[$1\]\]/g;

                # link convert - [: * ] -> [[ * ]]
                #
                s/\[\:(.*?)\]/\[\[$1\]\]/g;

                # link convert - __ * __ -> <u> * </u>
                #
                s/__(.*?)__/\<u\>$1\<\/u\>/g;

                # link convert - ` * ` -> <tt> * </tt>
                #
                s/`(.*?)`/\<tt\>$1\<\/tt\>/g;

                # link convert - {{{ * }}} -> <code><nowiki> * </code>
                # (if on same line)
                #
                s/\{\{\{(.*?)\}\}\}/<code\>\<nowiki\>$1\<\/nowiki\>\<\/code\>/g;

                # link convert - {{{ *  -> <pre> *
                # (}}} on different line)
                #
                s/\{\{\{(.*?)/\<pre\>\<nowiki\>$1/g;

                # link convert -  * }}} ->  * <\pre><\nowiki>
                # (if on same line)
                #
                s/(.*?)\}\}\}/$1\<\/nowiki\><\/pre\>/g;

                # strikethrough convert
                #
                s/--\((.*?)\)--/\<s\>$1\<\/s\>/g;

                # link convert - [wiki:cat * ] -> [[cat| * ]]
                #
                $this->ConvertWikiLinks(line=>\$_);

                # convert CamelCase links
                #
                $this->ConvertCamelLinks(line=>\$_);

                # link convert - /CommentPage -> Talk:PageName
                #
                @slashparts = split(/\//,$infile);
                my $filename = $slashparts[$#slashparts];
                @spaceparts = split(/(?=[A-Z])/,$filename);
                $name = join(" ",@spaceparts);
                s/\/CommentPage/\[\[Talk:$name\]\]/g;

                # Convert definition lists
                #
                # Partially built out, but not implemented
                #
                # MM has term, colon, colon, space, definition
                # MW has semicolon, space, term, space, colon, space, definition
                # s/(.*)\:\:\s(.*)/\;\s$1\s\:\s$2/g;

                ##########
                # deletions
                #

                # `` - don't need these (ex Myth``Blog on front page)
                #
                s/``//g;

                ##########
                # tables
                #

                # start of table/row?
                if(/^\|\|/) {
                        if($is_table == 0) {
                                # start of table
                                $is_table = 1;
                                s/^\|\|/\n\{\|border=1 cellpadding=1 cellspacing=0\|\n\|/;
                                }
                        else {
                                # start of row
                                s/^\|\|/\n\|-\n\|/;
                                }
                        }
                else {
                        # end of table?
                        # (i.e. in a table and the line doesn't start '||')
                        if ($is_table == 1) {
                                $is_table = 0;
                                s/(.*)$/$1\n\|\}\n/;
                                }
                        }

                # end of row (we just zap that)
                s/\|\|\s+$//;

                # all other '||' are just cell indicators
                s/\|\|/\n\|/g;

                print OUTFILE "$_";
        }

        # source text ended with unclosed table
        print OUTFILE "\n\|\}\n" if ($is_table == 1);

        close OUTFILE;
        close INFILE;
}
