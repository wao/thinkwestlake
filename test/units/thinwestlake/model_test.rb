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

    context "a context" do
        should "can define a method" do
            @name = "p1"
            @desc = "a desc"
            @value = 123

            @context = Context.new

            @context.__def_method__( 'tm', Proc.new{ |a| a+1 } )

            assert_equal 2, @context.tm(1)
        end
    end
    

    context "a template" do
        setup do
            @tmpl = Template.try_load( Pathname.new("test/res/templates/activity"), :activity )
        end

        should "can redefine name" do
            assert_equal "activity2", @tmpl.name
        end

        should "can define param by def_param" do
            assert_instance_of Parameter, @tmpl.context.__params__[:package_name]
        end

        should "can define a method by def_method" do
            assert_respond_to  @tmpl.context, :test_method
            assert_equal "a_class_instance", @tmpl.context.test_method( "AClassInstance" )
        end
    end

    context "a JavaFile" do
        should "auto generated text based on package_name and class_name" do
            tmpl_file = Pathname.new( "/fake_file_name" )
            context = ThinWestLake::Model::Context.from( :package_name=>"info.thinkmore.test", :class_name=>"MainActivity" )
            ThinWestLake::Model::Context.reveal(:to_matcher)
            ThinWestLake::Model::Context.reveal(:==)
            ThinWestLake::Model::Context.reveal(:mocha_inspect)

            base_dir = Pathname.new("/usr/src/main" ) 
            parent_dir = base_dir + "info/thinkmore/test" 
            file_path = parent_dir + "MainActivity.java"

            parent_dir.expects(:mkpath)
            base_dir.expects(:+).with( "info/thinkmore/test" ).returns( parent_dir )

            project = mock()
            project.stubs(:resolve_base_path).with( :java, :main ).returns( base_dir )

            java_file = JavaFile.new( tmpl_file, {:catalog=>:main} )
            
            ThinWestLake::Generator::ErbTmpl.expects( :erb ).with( tmpl_file, file_path, context )

            assert_equal "info/thinkmore/test", java_file.package_name_to_path( "info.thinkmore.test" )

            java_file.generate( project, context )
        end
    end
end
