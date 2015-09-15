def_param :package_name, "Name of package", :required=>true
def_param :class_name, "Name of Activity", :required=>true
#def_param :activity_layout_resid, "Layout Resource Id", :required=>false, :default=>"activity_main"

name "activity2"

def_method :activity_layout_resid do 
   class_name.underscore 
end

def_method :test_method do |var|
   var.underscore 
end

java "src/MainActivity.java", :catalog=>:main
