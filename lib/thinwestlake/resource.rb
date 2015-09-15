require 'thinwestlake/model'

module ThinWestLake
    class Resource
        def initialize(base_path)
            @base_path = base_path
        end

        def templates
            @templates ||= load_templates
        end

        def load_templates
            puts @base_path.to_s
            Pathname.new(@base_path+"templates").children.reduce({}) do |memo, entry|
                tmpl = Model::Template.try_load( entry, entry.basename.to_s )
                if tmpl
                    puts tmpl.name
                    name = tmpl.name.to_sym
                    raise "template #{name} is duplicated" if memo[name]
                    memo[name] = tmpl
                end
                memo
            end
        end
    end
end
