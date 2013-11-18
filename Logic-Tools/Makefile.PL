use inc::Module::Install;

name     'Logic-Tools';
all_from 'lib/Logic/Tools.pm';
author   q{lagutas <lagutas@gmail.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

