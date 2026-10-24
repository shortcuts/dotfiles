function rmgradle
    rm -rf ~/.gradle/caches
    rm -rf ~/.gradle/.tmp
    rm -rf ~/.gradle/daemon
    rm -rf ~/.gradle/configuration-cache
    rm -rf ~/.gradle/kotlin-profile
    rm -rf ~/.gradle/native
    rm -rf ~/.konan

    for repo in ~/Documents/locationjoystick ~/Documents/shinytracker
        find $repo \( -name build -o -name .gradle -o -name .kotlin \) -type d -not -path "*/.git/*" | xargs rm -rf
    end
end
