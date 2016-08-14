require "thinwestlake/version"
require "logger"

module ThinWestLake
    LOGGER = Logger.new( STDERR )
    def logger
        LOGGER
    end
end
