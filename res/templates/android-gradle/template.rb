copy 'build.gradle'
copy 'gitignore', :rename_to=>".gitignore"
copy 'settings.gradle'
copy 'gradle.properties'

sub_template 'app'
