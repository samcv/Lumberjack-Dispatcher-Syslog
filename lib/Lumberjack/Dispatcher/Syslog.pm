use v6.c;

=begin pod

=head1 NAME

Lumberjack::Dispatcher::Syslog - syslog dispatcher for the the Lumberjack logger

=head1 SYNOPSIS

=begin code

use Lumberjack;
use Lumberjack::Dispatcher::Syslog;

# Add the syslog dispatcher
Lumberjack.dispatchers.append: Lumberjack::Dispatcher::Syslog.new;

class MyClass does Lumberjack::Logger {
   method start() {
       self.log-info("Starting ...");
       ...
   }

   method do-stuff() {
      self.log-debug("Doing stuff ...");
      ...
      if $something-went-wrong {
         self.log-error("Something went wrong");
      }
   }
   method stop() {
       ...
       self.log-info("Stopped.");
   }
}

MyClass.log-level = Lumberjack::Debug;

=end code

=head1 DESCRIPTION

This provides a dispatcher for
L<Lumberjack|https://github.com/jonathanstowe/Lumberjack> which allows
you to log to your system's C<syslog> facility, this may log to various
log files in, for instance, C</var/log> depending on the configuration
of the syslog daemon.  Because the actual logging daemon being used
may differ from system to system (there is syslog-ng, rsyslog, syslog
"classic" etc,) you will need to refer to the local documentation or a
system administrator to determine the actual logging behaviour. Some
systems may for instance just drop "debug" or "trace" messages in the
default configuration (or put them in separate files.)

As a "plugin" to C<Lumberjack> this has no methods of its own.  All of
the following configuration can be passed to the constructor prior
to adding it to the "dispatchers" list of C<Lumberjack>. 

=head2 ident

This is the string 'ident' of the logger, it defaults to the program
name.

=head2 facility

This is the syslog facility which the logger will be opened for.  It
should be a value of the enumeration C<Log::Syslog::Native::LogFacility>,
it defaults to C<Local0>.  The "facility" is commonly used to determine
which file the logger will place the messages, you will need to check
the local configuration to determine the exact behaviour regarding the
different facilities.

=head2 format

This is the format that is used to format the message before sending
to the logger, this is described in the L<Lumberjack|https://github.com/jonathanstowe/Lumberjack/blob/master/Documentation.md#sub-format-message> documentation.

The default is "[%C - %S] : %M" which will emit "[<class> <method>] : <message>".

=head2 callframes

This is the integer callframe depth at which the formatter will try to
find the details of the execution frame of the log message.  The default
"4" should work in most cases but you may need to adjust it if you are
doing something more complicated and the subroutine name or filename
are wrong.

=head2 level-map

This is a Hash mapping the C<Lumberjack::Level> levels of the incoming
messages to the  C<Log::Syslog::Native::LogLevel> "priority" of the
syslog.  The default should be sufficient for most uses but you can
supply your own to work around a fixed configuration on your system.
The "priority" may influence where and indeed, if, a message will get
logged. The default mapping attempts to avoid using any priority that
typically gets sent to a console rather than files.

=head2 levels

This is a matcher for the levels that this dispatcher wishes to handle,
as described in the C<Lumberjack> documentation.

=head2 classes

This is a matcher for the classes that this dispatcher wishes to handle,
as described in the C<Lumberjack> documentaion. This and C<levels> may
be particularly useful in the syslog scenaria as it enables a mapping
of syslog "facilities" to different parts of an application.

=end pod

use Lumberjack :FORMAT;
use Log::Syslog::Native;

class Lumberjack::Dispatcher::Syslog does Lumberjack::Dispatcher {

    has Log::Syslog::Native                 $!logger;
    has Str                                 $.ident         =   $*PROGRAM-NAME;
    has Log::Syslog::Native::LogFacility    $.facility      =   Log::Syslog::Native::Local0;
    has Str                                 $.format        =   "[%C - %S] : %M";
    has Int                                 $.callframes    =   4;

    has %.level-map =   Trace => Log::Syslog::Native::Debug,
                        Debug => Log::Syslog::Native::Debug,
                        Info  => Log::Syslog::Native::Info,
                        Warn  => Log::Syslog::Native::Warning,
                        Error => Log::Syslog::Native::Error,
                        Fatal => Log::Syslog::Native::Alert;


    method log(Lumberjack::Message $message) {
        if not $!logger.defined {
            $!logger = Log::Syslog::Native.new(facility => $!facility, ident => $!ident);
        }

        my $formatted-message = format-message($!format, $message, callframes => $!callframes);
        $!logger.log(%!level-map{$message.level}, $formatted-message);
    }
}
# vim: expandtab shiftwidth=4 ft=perl6
