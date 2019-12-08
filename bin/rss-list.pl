Bareword "configfile" not allowed while "strict subs" in use at template line 22, <STDIN> line 2.
17: 
18: <DESCRIPTION>
19: 
20: =cut
21: 
22: % if (stash(configfile)) {
23: has configfile =>($ENV{CONFIG_DIR}||$ENV{HOME}.'/etc').'/' <%= stash('configfile') %>;
24: has config => sub {YAML::Tiny::LoadFile(shift->configfile)};
25: % }
26: option 'dryrun!', 'Print to screen instead of doing changes';
27: 
/home/stein/perl5/perlbrew/perls/perl-5.26.2/lib/site_perl/5.26.2/Mojo/Template.pm:166 (Mojo::Template)
/home/stein/git/utilities-perl/bin/../../utilities-perl/lib/SH/Code/Template.pm:110 (SH::Code::Template)
/home/stein/git/utilities-perl/bin/../../utilities-perl/lib/SH/Code/Template/ScriptX.pm:46 (SH::Code::Template::ScriptX)
/home/stein/git/utilities-perl/bin/template.pl:125 (main)
/home/stein/git/utilities-perl/bin/template.pl:139 (main)
