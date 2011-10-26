use inc::Module::Install;
name 'FDPool';
all_from 'lib/FDPool.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
