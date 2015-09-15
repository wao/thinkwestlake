def_param :package_name, "Name of package", :required=>true
def_param :class_name, "Name of Activity", :required=>true

def_method :activity_layout_resid do 
   class_name.underscore 
end

java "src/MainActivity.java", :catalog=>:main
