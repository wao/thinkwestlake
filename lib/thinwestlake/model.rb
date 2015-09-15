require 'active_support'
require 'active_support/core_ext'
require 'simple_assert'
require 'fattr'
require 'thinwestlake/generator'

module ThinWestLake::Model
    class BlankSlate < Module
        class << self

            # Hide the method named +name+ in the BlankSlate class.  Don't
            # hide +instance_eval+ or any method beginning with "__".
            def hide(name)
                warn_level = $VERBOSE
                $VERBOSE = nil
                if instance_methods.include?(name.to_sym) &&
                    name !~ /^(__.*|class_eval|respond_to\?|inspect|class)$/
                    #name !~ /^(__|instance_eval|tm_assert|equal\?|nil\?|!|is_a\?|byebug|throw|class|inspect|instance_variable_set|object_id|instance_variable_get|to_s|method|instance_of\?|respond_to\?|to_ary|hash|eql\?$)/
                    @hidden_methods ||= {}
                    @hidden_methods[name.to_sym] = instance_method(name)
                    undef_method name
                end
            ensure
                $VERBOSE = warn_level
            end

            def find_hidden_method(name)
                @hidden_methods ||= {}
                @hidden_methods[name] || superclass.find_hidden_method(name)
            end

            # Redefine a previously hidden method so that it may be called on a blank
            # slate object.
            def reveal(name)
                hidden_method = find_hidden_method(name)
                fail "Don't know how to reveal method '#{name}'" unless hidden_method
                define_method(name, hidden_method)
            end
        end

        alias_method :__methods__, :methods
        alias_method :__send__, :send
        alias_method :__class__, :class

        instance_methods.each { |m| hide(m.to_s) }
    end


    Parameter = Struct.new( :name, :description, :options, :value ) do
        DEFAULT_OPTIONS = { :required=>true, :type=>:string }

        SUPPORT_TYPES = Set.new( [:string, :int, :boolean] )

        def self.of( name, description, options = {}, &blk )
            value = options[:default]
            target_options = DEFAULT_OPTIONS.merge(options)
            check_type(target_options[:type])
            self.new( name.to_sym, description, target_options, value )
        end

        def required
            @options[:required] = true
        end

        def optional
            @options[:required] = false
        end

        def type(value)
            self.class.check_type(value)
            @options[:type] = value
        end

        def self.check_type(value)
            if !SUPPORT_TYPES.include? value.to_sym
                puts "Unsupport type #{value}"
            end
        end
    end

    class Context < BlankSlate
        def self.from(init_params={})
            context = self.new
            init_params.each_pair do |name,value|
                context.__def_param__( name.to_sym, name )
                context.__params__[ name.to_sym ].value = value
            end
            context
        end

        def initialize
            @params={}
        end

        def __meta_id__
            class << self
                self
            end
        end

        def __def_param__( param_name, description, options = {}, &blk )
            @params[ param_name.to_sym ] = Parameter.of( param_name, description, options )
            if blk
                 @params[ param_name.to_sym ].instance_eval &blk
            end

            __meta_id__.class_eval "def #{param_name}; @params[:\"#{param_name}\"].value; end"
        end

        def __def_method__( name, blk )
            self.__class__.__send__( :define_method, name.to_sym, &blk )
        end

        def __params__
            @params
        end

        def get_binding
            binding
        end
    end

    class Template
        fattr :name => nil
        
        attr_reader :context

        def self.try_load( base_dir, default_name )
            if base_dir.directory?
                rbfile = base_dir + "template.rb"
                if rbfile.exist?
                    tmpl = self.new( base_dir, default_name )
                    tmpl.instance_eval( rbfile.read, rbfile.to_s, 0 )
                    tmpl
                else
                    nil
                end
            else
                nil
            end
        end

        def initialize( base_dir, name, parent = nil )
            tm_assert{ base_dir.is_a? Pathname }
            @name = name
            @base_dir = base_dir
            @parent = parent
            @modules = {}
            @context = Context.new
            @elements = []
        end

        def has_module?(module_name)
            !get_module(module_name).nil?
        end

        def module(module_name, &blk)
            m = get_module(module_name)
            if m.nil? 
                m = Project.new(self)
                @modules[module_name.to_sym] = m
            end

            if !blk.nil?
                m.instance_eval &blk
            end

            m
        end

        def get_module(module_name)
            @modules[module_name.to_sym]
        end

        def def_param( param_name, description, options = {} )
            @context.__def_param__( param_name, description, options )
        end

        def def_method( name, &block )
            @context.__def_method__( name, block )
        end

        DEFAULT_JAVA_OPTION = { :catalog=>:main }

        def java(tmpl_file, options={})
            @elements << JavaFile.new( @base_dir + tmpl_file, options )
        end

        def generate(project)
            @elements.each do |elem|
                elem.generate( project, context )
            end
        end
    end

    class JavaFile
        attr_reader :tmpl_file, :options

        def initialize(tmpl_file, options)
            tm_assert{ tmpl_file.is_a? Pathname }
            @tmpl_file = tmpl_file
            @options = options
        end

        def package_name_to_path(package_name)
            package_name.gsub("\.", "/" )
        end

        def generate( project, context )
            base_dir = project.resolve_base_path( :java, options[:catalog] )
            tm_assert{ base_dir.is_a? Pathname }
            parent_dir = base_dir + package_name_to_path( context.package_name )
            parent_dir.mkpath

            ThinWestLake::Generator::ErbTmpl.erb( @tmpl_file, (parent_dir + "#{context.class_name}.java"), context )
        end
    end


    class Project
        def initialize( base_path )
            @base_path = Pathname.new(base_path)
        end

        def resolve_base_path( file_type, catalog )
            @base_path + "src/#{catalog}/#{file_type}"
        end
    end
end
