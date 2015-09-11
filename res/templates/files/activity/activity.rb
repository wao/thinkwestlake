def_param :package_name, "Name of package", :required=>true
def_param :class_name, "Name of Activity", :required=>true
def_param :activity_layout_resid, "Layout Resource Id", :required=>false, :default=>"activity_main"

java "src/MainActivity.java"
