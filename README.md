# demotivator
Script(s) to create old style demotivation poster images, as introduced by <a href="http://despair.com/">Despair</a>. Their derivatives are used by a number of sites like rusdemotivator.ru.

## Perl

`./perl/makemotivator.pl`

Basically, just a wrapper around ImageMagick' convert utility. Prerequisites:

  * perl 5.8+
  * ImageMagick 6.3+

Output file size is hardcoded at the moment (750x600, or 600x750 pixels).

Command like below
```
./makemotivator.pl -o ./demotivator-knowledge.png \ 
  -h "Knowledge is Power" -t "But information isn't" \ 
  -fd /usr/share/fonts/truetype/msttcorefonts -i Wikipedia-logo-v2.svg.png
```
produces image like this

<img src="http://download.boyandin.ru/images/demotivators/demotivator-knowledge.png" alt="Knowledge is Power" alt="Knowledge is Power" />

Script is self-documenting. Run it without parameters to see the instructions:

```
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
        Optional. Directory the font files are located in. Default: '/usr/share/fonts/msttcorefonts'.
    -wd workdir
        Optional. Directory used to store temporary files. Default: '/tmp'.
    -hf fontfilename
        Optional. Font file name used to write header. Default: times.ttf.
    -tf fontfilename
        Optional. Font file name used to write term. Default: arial.ttf.
    -hfs fontsize
        Optional. Font size the header is written with. Default: 48.
    -tfs fontsize
        Optional. Font size the term is written with. Default: 18.
    -v verboselevel
        Optional. If 0, only fatal errors are displayed. If 1, the script is more talkative about what it's doing. 
        Default: 0.
```
