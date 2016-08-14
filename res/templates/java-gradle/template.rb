#def_param :application_id, "Application Id for Play Store", {:use_if_not_exists=>:package}
def_param :full_class_name, "Name of full qualified class", :required=>true

def_method :package_name do
    full_class_name.split(".")[0..-1].join(".")
end

def_method :class_name do
    full_class_name.split(".").last
end

def_method :group_id do
    package_name
end

def_method :app_name do
    package_name.split(".").last
end

#plain 'build.gradle'
copy 'gitignore', :rename_to=>".gitignore"

java "src/main/Main.java", :catalog=>:main
java "src/test/MainTest.java", :catalog=>:test, :class_name_postfix=>"Test"

