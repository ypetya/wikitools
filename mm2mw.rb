#!/usr/bin/env ruby
# coding: utf-8

# MoinMoin to MediaWiki converter
# it is just the rewritten mm2mw.pl in ruby

input = ARGV[0]
output = ARGV[1]

output_array = []

def list_convert line,depth=5
  line = list_convert(line,depth-1) unless depth == 1
  line.gsub(%r{^#{' '*depth}\*(.*?)}){ "*"*depth + $1}
end

# link convert - [wiki:cat * ] -> [[cat| * ]]
# TODO: Camelcase links
# TODO: Link comments
def convert_wiki_links line
  line = line.gsub(/[\[]([^\s]+) (.*?)[\]]/){ "[[#{$1}| #{$2}]]" }
end

@@is_table = 0

open(input).readlines.each do |line|

  # line skips
  next if line =~ /^----$/;       # remove unneeded header lines

  # regexp substitutions

  #line = replace_hun_chars line

  # list convert
  line = list_convert(line)

  # list convert - numerical
  line = line.gsub(/^ 1.(.*?)/){ "##{$1}" }

  # link convert - [[BR]] -> <br>
  line = line.gsub(/\[\[BR\]\]/, "<br>" )

  # link convert superscripted - ^ * ^ -> <sup> * </sup>
  line = line.gsub(/\^(.*?)\^/){ "<sup>#{$1}</sup>" }

  # link convert subscripted - ,, * ,, -> <sub> * </sub>
  line = line.gsub(/\,\,(.*?)\,\,/){ "<sub>#{$1}</sub>" }

  # link convert smaller - ~- * -~ -> <small> * </small>
  line = line.gsub(/\~-(.*?)-\~/){ "<small>#{$1}</small>" }

  # link convert larger - ~+ * +~ -> <big> * </big>
  line = line.gsub(/\~\+(.*?)\+\~/){ "<big>#{$1}</big>" }

  # link convert - [# * ] -> [[ * ]]
  line = line.gsub(/\[\#(.*?)\]/){ "[[#{$1}]]" }

  # link convert - [" * "] -> [[ * ]]
  line = line.gsub(/\[\"(.*?)\"\]/){ "[[#{$1}]]" }

  # link convert - [: * ] -> [[ * ]]
  line = line.gsub(/\[\:(.*?)\]/){"[[#{$1}]]" }

  # link convert - __ * __ -> <u> * </u>
  line = line.gsub(/__(.*?)__/){ "<u>#{$1}</u>" }

  # link convert - ` * ` -> <tt> * </tt>
  line = line.gsub(/`(.*?)`/){ "<tt>#{$1}</tt>" }

  # link convert - {{{ * }}} -> <code><nowiki> * </code>
  # (if on same line)
  line = line.gsub(/\{\{\{(.*?)\}\}\}/){ "<code><nowiki>#{$1}</nowiki></code>" }

  # link convert - {{{ *  -> <pre> *
  # (}}} on different line)
  line = line.gsub(/\{\{\{(.*?)/){ "<pre><nowiki>#{$1}" }

  # link convert -  * }}} ->  * <\pre><\nowiki>
  # (if on same line)
  line = line.gsub(/(.*?)\}\}\}/){ "#{$1}</nowiki></pre>" }

  # strikethrough convert
  line = line.gsub(/--\((.*?)\)--/){ "<s>#{$1}</s>" }

  # link convert - [wiki:cat * ] -> [[cat| * ]]
  line = convert_wiki_links( line )
        
  # don't need this
  line =line.gsub('``','')


  # tables

  # start of table/row?
  if line =~ /^\|\|/
    if @@is_table == 0
      # start of table
      @@is_table = 1;
      line = line.gsub(/^\|\|/, "\n{|border=1 cellpadding=1 cellspacing=0|\n|")
    else
      # start of row
      line = line.gsub(/^\|\|/, "\n|-\n|")
    end
  else
    # end of table?
    # (i.e. in a table and the line doesn't start '||')
    if @@is_table == 1
      @@is_table = 0
      line = line.gsub(/(.*)$/){ $1 +"\n|}\n"}
    end
  end

  # end of row (we just zap that)
  line = line.gsub(/\|\|\s+$/,'')

  # all other '||' are just cell indicators
  line = line.gsub(/\|\|/,"\n|")

  output_array << line

end

# Write output
File.open(output, "w") do |f|
  output_array.each{|l| f.puts l}
end
