use Module::Build;
Module::Build->new(
    module_name => 'Language::Server',
    license     => 'perl',                          # 'perl' is kind of default licence
    requires    => { 
        'AnyEvent::Util'                    => 0,   # '0' indicate any version, maybe we can be more specific in future
        'Cpanel::JSON::XS'                  => 0,
        'Data::Printer'                     => 0,
        'File::Slurp'                       => 0,
        'IPC::Run3'                         => 0,
        'JSON::RPC2::Server'                => 0,
        'Moo'                               => 0,
        'MooX::Log::Any'                    => 0,
        'MooX::Singleton'                   => 0,
        'MooX::StrictConstructor'           => 0,
        'Perl::Tidy'                        => 0,
        'PPIx::EditorTools::RenameVariable' => 0,
        'Types::Standard'                   => 0,
    },
    # TODO: Specify test dependencies
)->create_build_script;
