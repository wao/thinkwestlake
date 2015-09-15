#!/usr/bin/env ruby
require_relative  "../../test_helper"

require 'thinwestlake/generator'
require 'thinwestlake/model'

class Test < Minitest::Test
    include ThinWestLake

    context 'A Generator' do
        should "generate a file from erb template by erb" do
            context = Model::Context.new
            context.__def_param__( :package_name, "Package Name" )
            context.__params__[:package_name].value="info.thinkmore.test";

            template_text="package <%= package_name %>;"
            generated_text="package info.thinkmore.test;"
            wr = mock("wr")
            wr.stubs(:is_a?).with(Pathname).returns(true)
            wr.expects(:write).with(generated_text)
            parent_dir = mock("parent_dir")
            parent_dir.stubs(:directory?).returns(true)
            wr.expects( :parent ).returns( parent_dir )
            template_file=mock("template_file")
            template_file.stubs(:is_a?).with(Pathname).returns(true)
            template_file.stubs(:read).returns(template_text)

            Generator.erb( template_file, wr, context )
        end

    end
end

