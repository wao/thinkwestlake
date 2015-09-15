require 'simple_assert'

module ThinWestLake::Generator
    # Encapule ERB operation into a single operation
    module ErbTmpl
        # Generate a file from a erb template file
        #
        # @param src [String] Path of ERB template file
        # @param dest [String] Generated file path
        # @param context [Object] A context object which should have a public get_binding method
        def self.erb( src, dest, context )
            tm_assert{ src.is_a? Pathname }
            tm_assert{ dest.is_a? Pathname }
            tm_assert{ dest.parent.directory? }
            #puts renderer.result(context.get_binding) 
            dest.write( self.render(src, context) )
        end

        def self.render(src, context)
            renderer = ERB.new( src.read )
            renderer.result(context.get_binding)
        end
    end

    def self.erb( src, dest, context )
        ErbTmpl.erb( src, dest, context )
    end

    class CopyFileGenerator
        def initialize( src_file )
            @src_file = src_file
        end

        def generate( context, target_path )
            FileUtils.copy_file @tmpl_file, target_path
        end
    end
end
