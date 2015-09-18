#def_param :application_id, "Application Id for Play Store", {:use_if_not_exists=>:package}

def_method :application_id do
    package_name
end

def_method :app_name do
    package_name.split(".").last
end

plain 'build.gradle'
copy 'gitignore', :rename_to=>".gitignore"

apply_template "../../activity"

[ "res/mipmap-hdpi/ic_launcher.png",
"res/mipmap-xhdpi/ic_launcher.png",
"res/mipmap-mdpi/ic_launcher.png",
"res/mipmap-xxhdpi/ic_launcher.png", ].each do |f|
    copy "src/main/#{f}"
end

[ "AndroidManifest.xml",
"res/values-w820dp/dimens.xml",
"res/values/strings.xml",
"res/values/styles.xml",
"res/values/dimens.xml",
"res/values/color1.xml",
"res/menu/menu_main.xml", ].each do |f|
    plain "src/main/#{f}"
end
