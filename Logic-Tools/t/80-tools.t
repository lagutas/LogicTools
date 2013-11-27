use strict;
use warnings;


use Test::More tests => 14;
use Test::Fork;


#загружаем тестируемый модуль
use_ok( 'Logic::Tools');																			#1

#создаем тестовый файл конфига
open(TEST_FILE,">>test.ini");
print TEST_FILE "[test_section]\n";
print TEST_FILE "test_item	=	test_value\n";
close(TEST_FILE);

#создаем объект
my $tools = Logic::Tools->new(	config_file =>	'test.ini',
								lock_file	=>	'test.pid',
								runas_user	=>	'root',
								logfile		=>	'test.log',
								sounds_dir	=>	'/var/lib/asterisk/sounds/ru/'
								);
#проверяем что объект принадлжеит классу
isa_ok( $tools, 'Logic::Tools' );																	#2

#проверка что Config::IniFiles установлен в системе
use_ok( 'Config::IniFiles');																		#3

#проверка работы функции read_config возвращает тестовые данные
is($tools->read_config('test_section', 'test_item'),'test_value','read_config work fine');			#4

#проверяем работу check_proc должен вернуть 1 если такого демона нет
is($tools->check_proc(),1,'check_proc work fine');													#5


use_ok('POSIX');																					#6
#проверяем работу процедуры start_daemon

fork_ok(1, sub
				{
 					is($tools->start_daemon(),1,'read_config work fine');							#7,8
 					#удаляекм тестовый lock_file
					unlink("test.pid");
        		});

is($tools->logprint("info","test"),1,'logprint work fine');											#9
open(my $logfile,'<','test.log');
my $test_log_string=<$logfile>;
like( $test_log_string, qr/^\d{4}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2}\s\d+\sms\s\[\d+\]\sINFO:\stest$/, "logfile is ok" );	#10

my $AGI = new Asterisk::AGI;
my %input = $AGI->ReadParse();

use Asterisk::AGI;
use_ok( 'Asterisk::AGI');	#11
is($tools->AGIDateSpeach('12','10'),"error",'AGIDateSpeach work fine');		#12
is($tools->AGIDateSpeach($AGI, '10','10'),"error",'AGIDateSpeach work fine');	#13
is($tools->AGITimeSpeach('12','10'),"error",'AGITimeSpeach work fine');		#14

close($logfile);

#удаляем тестовый файл конфига
unlink("test.ini");

#удалям тестовый файл лога
unlink("test.log");
