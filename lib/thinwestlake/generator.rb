module ThinWestLake::Generator
    # Encapule ERB operation into a single operation
    module ErbTmpl
        # Generate a file from a erb template file
        #
        # @param src [String] Path of ERB template file
        # @param dest [String] Generated file path
        # @param context [Object] A context object which should have a public get_binding method
        def erb( src, dest, context )
            #puts "render #{src} to #{dest}"
            FileUtils.mkdir_p File.dirname(dest) if !File.exist? File.dirname(dest)
            File.open( dest, "w" ) do |wr|
                #puts renderer.result(context.get_binding) 
                wr.write( render(src, context) )
            end
        end

        private def render(src, context)
            renderer = ERB.new( File.read(src) )
            renderer.result(context.get_binding)
        end
    end

    class CopyFileGenerator
        def initialize( src_file )
            @src_file = src_file
        end

        def generate( context, target_path )
            FileUtils.copy_file @tmpl_file, target_path
        end
    end

    class PlainFileGenerator
        include ErbTmpl

        def initilize( tmpl_file )
            @tmpl_file = tmpl_file
        end

        def generate( context, target_path )
            erb( @tmpl_file, target_path, context )
        end
    end

    class JavaGenerator
        include ErbTmpl

        def initilize( tmpl_file )
            @tmpl_file = tmpl_file
        end

        def generate( context, base_dir, *class_names )
            class_name_segments = class_names.reduct([]) do |memo, value|
                memo.concat value.split(".")
            end

            target_path = base_dir + "/" + class_name_segments.join("/") + ".java"
            erb( @tmpl_file, target_path, context )
        end
    end
end
