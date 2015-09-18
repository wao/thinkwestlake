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
                    name !~ /^(__.*|class_eval|respond_to\?|inspect|class|nil\?|instance_eval)$/
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

    class ContextWrap < BlankSlate
        fattr :params

        def initialize(upper_context,params={})
            @upper_context = upper_context
            @params = params
        end

        def get_binding
            binding
        end

        def method_missing(symbol, *args)
            puts "symbol:#{symbol}"
            if @params[symbol].nil?
                @upper_context.__send__( symbol, *args )
            else
                @params[symbol]
            end
        end
    end

    class Template
        fattr :name => nil
        
        attr_reader :context

        def self.try_load( base_dir, default_name, parent = nil )
            if base_dir.directory?
                rbfile = base_dir + "template.rb"
                if rbfile.exist?
                    tmpl = self.new( base_dir, default_name, parent )
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
            if parent
                @context = parent.context
            else
                @context = Context.new
            end
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

        def java(tmpl_file, options={}, &blk)
            elem = JavaFile.new( @base_dir + tmpl_file, options )
            @elements << elem
        end

        def copy(tmpl_file, options={})
            @elements << CopyFile.new( @base_dir + tmpl_file, options.merge( :target_path=>tmpl_file ) )
        end

        def plain(tmpl_file, options={})
            @elements << PlainFile.new( @base_dir + tmpl_file, options.merge( :target_path=>tmpl_file ) )
        end

        def sub_template(path,options={})
            @elements << SubTemplate.new( self, @base_dir , path, options )
        end

        DEFAULT_APPLY_TEMPLATE_OPTIONS={:using_parent_path=>true}

        def apply_template(path,options={})
            @elements << SubTemplate.new( self, @base_dir , path, DEFAULT_APPLY_TEMPLATE_OPTIONS.merge(options) )
        end

        def generate(project,context=nil)
            if context.nil?
                context = @context
            end

            @elements.each do |elem|
                puts "Generate from #{elem.name}"
                elem.generate( project, context )
            end
        end
    end

    class SubTemplate
        def name
            @template.name
        end

        def initialize(base_template, base_dir,template_path, options)
            @base_template = base_template
            @base_dir = base_dir
            @template_path = template_path
            @template = Template.try_load( base_dir + @template_path, template_path, base_template )
            tm_assert{ !@template.nil? }
            @options = options
        end

        def make_project(project)
            if @options[:using_parent_path]
                project
            else
                project = Project.new( project.base_path + @template_path )
                project.base_path.mkpath
                project
            end
        end

        def generate(project, context)
            @template.generate(make_project(project),context)
        end
    end

    module RelativeTemplate
        def name
            @tmpl_file
        end

        def make_target_path(project,context)
            target_path = project.base_path + @options[ :target_path ]
            target_path.parent.mkpath
            if @options[:rename_to]
                new_name = @options[:rename_to]
                if new_name.is_a? Proc
                    new_name = context.instance_eval &new_name
                end
                target_path = target_path.parent + new_name
            end
            target_path
        end
    end

    class CopyFile
        include RelativeTemplate

        attr_reader :tmpl_file, :options

        def initialize(tmpl_file, options)
            tm_assert{ tmpl_file.is_a? Pathname }
            @tmpl_file = tmpl_file
            @options = options
        end

        def generate( project, context )
            FileUtils.copy_file( @tmpl_file, make_target_path(project,context) )
        end
    end

    class PlainFile
        include RelativeTemplate

        attr_reader :tmpl_file, :options

        def initialize(tmpl_file, options)
            tm_assert{ tmpl_file.is_a? Pathname }
            @tmpl_file = tmpl_file
            @options = options
        end

        def generate( project, context )
            ThinWestLake::Generator.erb( @tmpl_file, make_target_path(project,context), context )
        end
    end

    class JavaFile
        attr_reader :tmpl_file, :options

        def name
            @tmpl_file
        end

        def initialize(tmpl_file, options)
            tm_assert{ tmpl_file.is_a? Pathname }
            @tmpl_file = tmpl_file
            @options = options
        end

        def package_name_to_path(package_name)
            package_name.gsub("\.", "/" )
        end

        def package_name( project, context )
            context.package_name
        end

        def class_name( project, context )
            "#{@options[:class_name_prefix]}#{context.class_name}#{@options[:class_name_postfix]}"
        end

        def generate( project, context )
            base_dir = project.resolve_base_path( :java, options[:catalog] )
            tm_assert{ base_dir.is_a? Pathname }
            parent_dir = base_dir + package_name_to_path( package_name(project,context) )
            parent_dir.mkpath

            ThinWestLake::Generator.erb( @tmpl_file, (parent_dir + "#{class_name(project,context)}.java"), ContextWrap.new( context, :package_name=>package_name(project,context), :class_name=>class_name(project,context) ) )
        end
    end


    class Project
        attr_reader :base_path

        def initialize( base_path )
            @base_path = Pathname.new(base_path)
        end

        def resolve_base_path( file_type, catalog )
            @base_path + "src/#{catalog}/#{file_type}"
        end
    end
end
