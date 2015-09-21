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

java "src/main/MainActivity.java", :catalog=>:main
java "src/test/MainActivityTest.java", :catalog=>:test, :class_name_postfix=>"Test"
java "src/androidTest/MainActivityTest.java", :catalog=>:androidTest, :class_name_postfix=>"Test", :package_name_postfix=>".test"

plain "src/main/res/layout/activity_main.xml", :rename_to=>Proc.new{ "#{activity_name.underscore}.xml" }
