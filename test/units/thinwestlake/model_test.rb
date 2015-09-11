#!/usr/bin/env ruby
require_relative  "../../test_helper"
require 'thinwestlake/model'

include ThinWestLake::Model

class TestModel < Minitest::Test
    context "a parameter create without options" do
        setup do
            @name = "p1"
            @desc = "a test parameter"
            @p = ThinWestLake::Model::Parameter.of( @name, @desc )
        end

        should "change name to symbol" do
            assert_equal @name.to_sym, @p.name
        end

        should "keep desc as created" do
            assert_equal @desc, @p.description
        end

        should "has nil default value" do
            assert_nil @p.value
        end

        should "has default attr :required=>true" do
            assert @p.options[:required]
        end

    end

    context "a parameter" do
        should "can overload attr :required" do
            @name = "p1"
            @desc = "a test parameter"
            @p = ThinWestLake::Model::Parameter.of( @name, @desc, {:required=>false} )

            assert !@p.options[:required]
        end

        should "can assign default value via options {:default=>value}" do
            @name = "p1"
            @desc = "a test parameter"
            @p = ThinWestLake::Model::Parameter.of( @name, @desc, {:default=>"default"} )
            assert_equal "default", @p.value
        end
    end

    context "a context which call a __def_param__ " do
        setup do
            @name = "p1"
            @desc = "a desc"
            @value = 123

            @context = Context.new

            @context.__def_param__( @name, @desc, :default=>@value )
        end

        should "define a method which name is same as param_name" do
            assert_respond_to @context, @name.to_sym
            assert_equal @value, @context.__send__( @name.to_sym )
        end

        should "define a paramter can be queryed by __params__" do
            assert @context.__params__[@name.to_sym]
        end
    end
end
