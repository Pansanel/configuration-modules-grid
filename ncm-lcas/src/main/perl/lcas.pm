# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}
#
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################


package NCM::Component::lcas;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use File::Path;

use EDG::WP4::CCM::Element;


local(*DTA);

##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/lcas";
    
    # Retrieve configuration
    my $lcas_config = $config->getElement($base)->getTree();

    # If dbpath is specified, assume this is the configuration legacy format.
    # Move configuration under 'db': schema enforces there is nothing else under 'db'
    # in this case.
    if ( $lcas_config->{dbpath} ) {
        my %db_params;
        $db_params{dbpath} = $lcas_config->{dbpath};
        $db_params{module} = $lcas_config->{module};
        $lcas_config->{db} = [];
        push @{$lcas_config->{db}}, %db_params;
    }

    foreach my $db_config (@{$lcas_config->{db}}) {
        my $dbpath = $db_config->{dbpath};
        $self->info("Processing LCMAPS database $dbpath...");

        # we will be cautious and only write the set of configuration
        # files if we are entirely successful in generating all of them.
        # Meanwhile, $cfiles{$path} will retain the content.
        my %cfiles=();

        $cfiles{$dbpath}="";
        $cfiles{$dbpath}.="# LCAS plugin list\n generated by ncm-lcas as $dbpath.\n";
        $cfiles{$dbpath}.="# DO NOT EDIT BY HAND -- edit node configuration instead.\n";
        $cfiles{$dbpath}.="#\n";
    
        if ( $db_config->{module} ) {
    
            for my $mod_config (@{$db_config->{module}}) {
                # Path is mandatory in the schema
                my $modname = $mod_config->{path};
                $self->debug(1,"LCAS: configuring module $modname");
    
                # Path is mandatory in the schema
                $cfiles{$dbpath}.="pluginname=".$modname;
    
                if ( $mod_config->{args} ) {
                    $cfiles{$dbpath}.=",pluginargs=".$mod_config->{args},
                }
                $cfiles{$dbpath}.="\n";
    
                # optionally write the module configuration as well in a separate file
                if ( $mod_config->{conf} ) {
                    my $cfname=$mod_config->{conf}->{path};
                    $self->debug(1,"Building configuration for module $modname ($cfname)...");
                    $cfiles{$cfname}="";
    
                    # may I write a header here?
                    unless ( $mod_config->{conf}->{noheader} ) {
                       $cfiles{$cfname}.="# LCAS module configuration for module $modname generated by ncm-lcas\n";
                       $cfiles{$cfname}.="# DO NOT EDIT BY HAND -- edit node configuration instead\n";
                       $cfiles{$cfname}.="#\n";                  
                    };
    
    
                    if ( $mod_config->{conf}->{content} ) {
                        foreach my $line (@{$mod_config->{conf}->{content}}) {
                          $cfiles{$cfname}.=$line."\n";
                        }
                    }
                } else {
                    $self->debug(1,"No specific configuration found for module $modname");
                }
            }
        }

        # Actually write files build before.    
        foreach my $file ( keys %cfiles ) {
            $self->info("Checking $file...");
            my $result = LC::Check::file($file,
                                         backup => ".old",
                                         contents => $cfiles{$file}
                                        );
            if ( $result < 0 ) {
              $self->error("Failed to update file $file\n");
            }
        }
        
    }


    return 1;
}

1;      # Required for PERL modules


