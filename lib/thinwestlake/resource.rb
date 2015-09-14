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
            Pathname.new(@base_path+"/templates").children.reduce({}) do |memo, entry|
                if entry.directory?
                    name = entry.basename.to_s.to_sym
                    raise "template #{name} is duplicated" if memo[name]
                    memo[name] = Model::Template.new( entry, name )
                end

                memo
            end
        end
    end
end
