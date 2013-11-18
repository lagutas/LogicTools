package Logic::Tools;

use 5.10.1;
use strict;
use warnings;
use Config::IniFiles;
use POSIX;
use Log::Any;
use Log::Any::Adapter;
use Log::Log4perl qw(:easy);
Log::Any::Adapter->set('Log4perl');

=head1 NAME

Logic::Tools - The great new Logic::Tools!

=head1 VERSION

Version 0.01

=cut

my @ISA = qw(Logic);
our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Logic::Tools;

    my $foo = Logic::Tools->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS
=cut

=head1 constructor
=cut

sub new
{
    my $invocant = shift; # первый параметр - ссылка на объект или имя класса
    my $class = ref($invocant) || $invocant; # получение имени класса
    my $self = { @_ }; # ссылка на анонимный хеш - это и будет нашим новым объектом, инициализация объекта
    $self->{NAME}=$invocant;
    $self->{VERSION}=$VERSION;

    if($self->{'logfile'})
    {
        Log::Log4perl->easy_init(
                                    {level  => 'INFO', 
                                     file   => '>>'.$self->{'logfile'},
                                     layout => "%d %r ms [%P] %p: %m%n",
                                    }
                                );
    }

    bless($self, $class); # освящаем ссылку в объект
    return $self; # возвращаем объект
}

=head1 METHODS
=cut

sub read_config
{
	my $model=shift;
    my $self=$model->new(%$model,@_);

    my $config_file = $self->{'config_file'};
	my $section = shift || die "не задана секция для чтения конфига";
	my $param = shift || die "не задан параметр для чтения конфига";

    my $cfg=new Config::IniFiles( -file => $config_file ) or die "Error: не найден конфигурационный файл $config_file";

	my $value = $cfg->val( $section, $param);

	die "Не найден параметр ".$param." в секции ".$section unless(defined($value));

	return $value;
}


sub check_proc
{
    my $model=shift;
    my $self=$model->new(%$model,@_);

    my $pid_f = $self->{'lock_file'};
    
    # Проверяем запущен ли уже процесс
    if( -e $pid_f ) 
    {

        open(my $pid_file,'<',$pid_f) || die "не удалось открыть файл $pid_f";
        my $pid=<$pid_file>;
        close $pid_file;
        chomp $pid;
        
        # Процесс запущен, но активного процесса с указанным PID нет
        unless( -e "/proc/$pid" )
        {
            #print STDERR "Файл блокировки уже существует, но демон с pid=$pid не существует\n";
            die "Не удается удалить файл блокировки $pid_f\n" if ( !unlink $pid_f );
            #print STDERR "Файл блокировки удален\n";
        }
        else
        {
            die "Процесс уже запущен. Процесс с pid=$pid\n";
        }
    }
    return 1;
} 


sub logprint
{
    my $model=shift;
    my $self=$model->new(%$model,@_);

    my $loglevel=shift;
    my $message=shift;

    my $log = Log::Any->get_logger();
    given($loglevel)
    {
        when(/^trace/)
        {
            $log->trace($message);
        }
        when(/^debug/)
        {
            $log->debug($message);
        }
        when(/^info/)
        {
            $log->info($message);
        }
        when(/^notice/)
        {
            $log->notice($message);
        }
        when(/^warning/)
        {
            $log->warning($message);
        }
        when(/^error/)
        {
            $log->error($message);
        }
        when(/^critical/)
        {
            $log->critical($message);
        }
        when(/^alert/)
        {
            $log->alert($message);
        }
        when(/^emergency/)
        {
            $log->emergency($message);
        }
    }
    return 1;
}

sub start_daemon
{
    my $model=shift;
    my $self=$model->new(%$model,@_);

    my $runas_user=$self->{'runas_user'};
    my $lock_file=$self->{'lock_file'};

    my ($name, $passwd, $uid, $gid) = getpwnam($runas_user) or die "невозможно запуститься под $runas_user";
    
    my $pid = fork();
    
    die "не удается создать форк: $!" unless(defined($pid));
    
     
    if($pid)
    {
        # Запись файле блокировки
        open(my $pid_file, ">" ,$lock_file) || die "Не удалось создать файл блокировки $lock_file\n";
        print $pid_file "$pid";
        close $pid_file;
        chown $uid, $gid, $lock_file;
        exit;
    } 
    else
    {
        # daemon
        setpgrp();
        select(STDERR); $| = 1;
        select(STDOUT); $| = 1;
        #syslog(LOG_INFO, "---------------------------------------");
        #syslog(LOG_INFO, "Скрипт запущен");
    }

    # Сброс привилегий
    setuid($uid);
    $< = $uid;
    $> = $uid;

    return 1;
}

=head1 AUTHOR

lagutas, C<< <lagutas at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-logic-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Logic-Tools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Logic::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Logic-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Logic-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Logic-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Logic-Tools/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 lagutas.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Logic::Tools
