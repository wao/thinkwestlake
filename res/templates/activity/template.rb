def_param :package_name, "Name of package", :required=>true
def_param :activity_name, "Name of Activity", :required=>true

def_method :activity_layout_resid do 
   activity_name.underscore 
end

def_method :app_name do
    package_name.split(".").last
end

def_method :class_name do
    activity_name
end

java "src/MainActivity.java", :catalog=>:main
java "src/test/MainActivityTest.java", :catalog=>:test, :class_name_postfix=>"Test"

plain "src/main/res/layout/activity_main.xml", :rename_to=>Proc.new{ "#{activity_name.underscore}.xml" }
