#!/usr/bin/env ruby
require_relative  "../../test_helper"

require 'thinwestlake/resource'

class TestResource < Minitest::Test
    include ThinWestLake

    context "a resource " do
        setup do
            @resource = Resource.new( File.dirname( __FILE__ ) + "/../../res" )
        end

        should "enumlate all the templates" do
            names = [ :java, :activity, :gradle ].sort
            assert_equal names, @resource.templates.keys.sort
        end

    end
end
